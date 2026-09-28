// The Filmation games' castles, out of a snapshot of the original game and back
// into it, in the browser: what the standalone room editor does with no Python
// and no server.
//
// Knight Lore, Pentagram and, in time, Alien 8 keep their castles the same way
// -- room records naming templates, templates as chains of pieces, a table of
// floor shapes -- and differ in where the tables are, what names them, and
// what a room's record holds. Each game is a profile below; everything else is
// shared. The disassemblies in this repository are where each profile's
// numbers come from: every address is a label there, and the notes under
// notes/<game>/room-building.md say how the game reads them.
//
// For Knight Lore, knightlore_rooms.py is a second implementation in Python,
// and room_editor_test.js holds the two to agreeing byte for byte. What this
// reads and writes is a 48K .sna as bytes; a .z80 is turned into one on the
// way in, so that every build starts from the same kind of file.
//
// Plain functions over Uint8Arrays, no DOM: the page draws the sprite sheet
// from what sheetPixels() returns, and Node runs the test.
'use strict';

const SNA_HEADER = 27;
const SNA_SIZE = SNA_HEADER + 0xC000;
const RAM_START = 0x4000;

const ROOM_SIZE_LIMIT = 32;             // bits 3-7 of the attribute byte, in both games
// A half-size keeps $80 plus and minus it inside a byte; a floor is any height.
const SHAPE_RANGE = { u: [1, 127], v: [1, 127], z: [0, 255] };
const SCENERY_STRIDE = 8;               // graphic, U, V, Z, size U, V, Z, flags
const SCENERY_END = 0xFF;
const GROUP_LIMIT = 8;
const CELLS = 8;
const LEVELS = 4;
const INKS = 8;
const RECORD_LIMIT = 255;
const GAME_MIRROR = 0x40;               // bit 6 of a piece's flags, in every game
const HALF_U = 0x01;
const HALF_V = 0x02;
const RAISE_Z = 0xFC;

// Where the player stands when a game starts, whichever starting room it is:
// Knight Lore's plyr_spr_init_data at $D1A1 and Pentagram's PLAYER_START at
// $C3EF both put him in the middle of the floor, in a box 5 either way and $17
// high.
const START_SPOT = { u: 0x80, v: 0x80, z: 0x80, sizeU: 5, sizeV: 5, sizeZ: 0x17 };
// room_unpack's arithmetic for an object's place, as room_model.js has it.
const CELL = 16;
const CELL_ORIGIN = 72;
const HALF_CELL = 8;
const LEVEL_Z = 12;
const Z_MASK = 0xFC;
const FIRST_REAL_GRAPHIC = 2;           // graphic 1 is a blank the builders step over

const SHAPE_NAMES = ['square', 'narrowU', 'narrowV'];

// --- the games -------------------------------------------------------------
//
// A profile says, for one game:
//
//   roomSizes      room_size_tbl, which stays put; the rooms follow it
//   regionEnd      where the room tables must stop: the next thing in memory
//   operands       the addresses of the operands naming the rooms and the two
//                  template tables, which a build patches when it moves them
//   original       where the game has those tables, and how many templates
//   after          which template table follows the rooms, then the other: the
//                  walk that finds a room stops at the first
//   walkBounded    whether that walk stops at the end of the rooms (Knight
//                  Lore) or runs on through memory for a room that is not
//                  there (Pentagram), which makes every room a doorway or a
//                  start names a room that must exist
//   destinations   whether a scenery entry is followed by a byte, the room a
//                  doorway leads to (Pentagram), or stands alone (Knight Lore)
//   objectStride   an object template's piece: 6 bytes with Knight Lore's
//                  placement nudge, or 5 without
//   passableBit    the flags bit that lets things through a piece, if known
//   emptyAt        where an empty template points: at a body of its own (a
//                  lone zero), or at its table, as Pentagram's unused ones do
//   pool           the object records a room may fill, and what one more hits
//   startRooms     the table a game's starting room is picked from
//   specials       the collectables -- Knight Lore's charms, Alien 8's valves
//                  -- or none
//   sprites        the graphic table, and the runs of sprite records the game
//                  may have mirrored in place as it drew them
//   attr           where a room's attribute byte keeps its ink and its shape
//   startSpot      where the player is put, whichever starting room
//   yOrigin        the designer's projection origin: rules.yOrigin
//   pages          Alien 8's two pages of object templates, or none
//   nudgeHeader    Alien 8's header that sets the placement nudge, or none

const KNIGHT_LORE = {
  id: 'knightlore',
  title: 'Knight Lore',
  roomSizes: 0x6248,
  regionEnd: 0x6FF2,                    // special_objs_tbl
  operands: {
    rooms: [0xD3CD],                    // retrieve_screen's LD HL,location_tbl
    objectTable: [0xD3CA, 0xD462],      // its LD BC (the walk's end); next_fg_obj's LD HL
    sceneryTable: [0xD42B]              // next_bg_obj's LD BC
  },
  original: { rooms: 0x6251, objectTable: 0x6BD1, sceneryTable: 0x6CE2,
              objectCount: 29, sceneryCount: 24 },
  after: ['objectTable', 'sceneryTable'],
  walkBounded: true,
  destinations: false,
  objectStride: 6,
  passableBit: 0x02,
  emptyAt: 'body',
  pool: { limit: 36, overrun: 'overwrites the font and the room tables' },
  startRooms: { at: 0xD1E2, count: 4 },
  specials: { table: 0x6FF2, rows: 32, stride: 9, wanted: 0xC27D, wantedCount: 14, kinds: 8 },
  sprites: { table: 0x7112, count: 256, runs: [[0x728C, 0xAF6C]], leftRight: 0x40, upsideDown: 0 },
  attr: { inkShift: 0, shapeShift: 3, shapes: 32 },
  startSpot: START_SPOT,
  yOrigin: 296,
  objectLimit: 32,
  pages: null,
  nudgeHeader: null,
  sceneryNames: [
    'arch_n', 'arch_e', 'arch_s', 'arch_w',
    'tree_arch_n', 'tree_arch_e', 'tree_arch_s', 'tree_arch_w',
    'gate_0', 'gate_1', 'gate_2', 'gate_3',
    'walls_0', 'walls_1', 'walls_2',
    'trees_0', 'trees_1', 'trees_2',
    'wizard', 'pot',
    'high_arch_e', 'high_arch_s', 'high_arch_e_base', 'high_arch_s_base'
  ].map(function (n) { return 'scenery_' + n; }),
  objectNames: [
    'block', 'fire', 'ball_ud_y', 'rock', 'gargoyle', 'spike', 'chest',
    'table', 'guard_ew', 'ghost', 'fire_ns', 'block_high', 'ball_ud_xy',
    'guard_square', 'block_ew', 'block_ns', 'moveable_block', 'spike_high',
    'spike_ball', 'spike_ball_falling', 'fire_ew', 'dropping_block',
    'collapsing_block', 'ball_bounce', 'ball_ud', 'repel_spell',
    'gate_ud_1', 'gate_ud_2', 'ball_ud_x'
  ].map(function (n) { return 'object_' + n; })
};

// Pentagram, from its disassembly: BUILD_ROOM at $C92C and the notes under
// notes/pentagram/room-building.md.
const PENTAGRAM_DOORS = { 0: 'door_a_n', 1: 'door_a_e', 2: 'door_a_s', 3: 'door_a_w',
                          4: 'door_b_n', 5: 'door_b_e', 6: 'door_b_s', 7: 'door_b_w',
                          24: 'door_c_n', 25: 'door_c_e', 26: 'door_c_s', 27: 'door_c_w' };
const PENTAGRAM = {
  id: 'pentagram',
  title: 'Pentagram',
  roomSizes: 0x5E07,                    // ROOM_SIZES
  regionEnd: 0x6DD7,                    // GRAPHICS, the graphic table
  operands: {
    rooms: [0xC940],                    // BUILD_ROOM's LD HL,ROOMS
    sceneryTable: [0xC93D, 0xC98E],     // its LD BC,SCENERY_TABLE (the walk's end, and the index)
    objectTable: [0xC930]               // its LD HL,OBJECT_TABLE (TEMPLATES_AT)
  },
  original: { rooms: 0x5E10, sceneryTable: 0x696D, objectTable: 0x6CE5,
              sceneryCount: 32, objectCount: 31 },
  after: ['sceneryTable', 'objectTable'],
  walkBounded: false,
  destinations: true,
  objectStride: 5,
  passableBit: null,
  emptyAt: 'table',
  pool: { limit: 48, overrun: 'runs down over the bolts and the player’s own records' },
  startRooms: { at: 0xC2E8, count: 4 },   // START_ROOMS
  specials: null,
  sprites: { table: 0x6DD7, count: 172,
             runs: [[0x6F2F, 0x8355], [0x8547, 0x9395], [0x9397, 0xA709], [0x84AD, 0x853F]],
             leftRight: 0x40, upsideDown: 0x80 },
  attr: { inkShift: 0, shapeShift: 3, shapes: 32 },
  startSpot: START_SPOT,
  yOrigin: 296,
  // A header's template 31 switches to a second page Pentagram never uses.
  objectLimit: 31,
  pages: null,
  nudgeHeader: null,
  sceneryName: function (i) {
    return PENTAGRAM_DOORS[i] || 'scenery_' + String(i).padStart(2, '0');
  },
  objectName: function (i) { return 'object_' + String(i).padStart(2, '0'); },
  // Only a doorway carries a room to lead to; the designer and castle.py
  // decide which scenery is one by its place in the table, as the game does.
  isDoorway: function (index) { return PENTAGRAM_DOORS[index] !== undefined; }
};

// Alien 8, from its disassembly: BUILD_ROOM at $CCA7 and
// notes/alien8/room-building.md. Knight Lore's grid and exits, Pentagram's
// builder, and two things of its own in a room's groups: a header of template
// 0 sets the placement nudge for the groups after it (the byte after it), and
// template 31 moves on to a second page of object templates (the byte after it
// skipped). Its rooms' inks are in bits 3-5 of the attribute byte -- bits 0-2
// are zero on the tape, and RESET_ROOM_COLOURS copies 3-5 into them every
// game, since an activated chamber turns them white -- and its sizes in 6-7.
const ALIEN8_DOORS = { 0: 'door_n', 1: 'door_e', 2: 'door_s', 3: 'door_w',
                       10: 'door_high_e', 11: 'door_high_s' };
const ALIEN8 = {
  id: 'alien8',
  title: 'Alien 8',
  roomSizes: 0x6460,                    // ROOM_SIZES
  regionEnd: 0x76E3,                    // PLACES, where the valves can lie
  operands: {
    rooms: [0xAC74, 0xCAD3, 0xCCBB],    // SUMMARISE_CHAMBERS, RESET_ROOM_COLOURS, BUILD_ROOM
    objectTable: [0xAC81, 0xCAD6, 0xCCA8, 0xCCB8],   // the walks' ends, and TEMPLATES_AT
    sceneryTable: [0xCD19]              // BUILD_NEXT_BACKGROUND's LD BC,BACKGROUND_TABLE
  },
  original: { rooms: 0x6469, objectTable: 0x73C8, sceneryTable: 0x7519,
              objectCount: 40, sceneryCount: 14 },
  after: ['objectTable', 'sceneryTable'],
  walkBounded: true,
  destinations: false,
  objectStride: 5,
  passableBit: null,
  emptyAt: 'body',
  pool: { limit: 52, overrun: 'is past the records, and the loop that clears them after a room ' +
                             'stops only at their end exactly, so it would never stop' },
  startRooms: { at: 0xCA9E, count: 4 },   // START_ROOMS
  specials: { table: 0x76E3, rows: 36, stride: 9, wanted: null, wantedCount: 0, kinds: 8 },
  sprites: { table: 0x7827, count: 132, runs: [[0x792F, 0xA631]], leftRight: 0x40, upsideDown: 0x80 },
  attr: { inkShift: 3, shapeShift: 6, shapes: 4 },
  // START_TEMPLATE: U and V 128, the legs at Z 64 and the top at 76, half-sizes
  // 7 and heights 12 and 11 -- a box from 64 to 87.
  startSpot: { u: 0x80, v: 0x80, z: 0x40, sizeU: 7, sizeV: 7, sizeZ: 23 },
  yOrigin: 232,
  objectLimit: 60,
  pages: { slots: 32, perPage: 30, escape: [0xF8, 0x00] },
  nudgeHeader: 0x00,
  sceneryName: function (i) {
    return ALIEN8_DOORS[i] || 'background_' + String(i).padStart(2, '0');
  },
  objectName: function (slot) { return 'object_' + String(slot).padStart(2, '0'); },
  doorways: { door_n: 'n', door_e: 'e', door_s: 's', door_w: 'w', door_high_e: 'e', door_high_s: 's' }
};

const GAMES = [KNIGHT_LORE, PENTAGRAM, ALIEN8];

function sceneryNameOf(game, i) {
  if (game.sceneryName) return game.sceneryName(i);
  return i < game.sceneryNames.length ? game.sceneryNames[i] : 'scenery_extra_' + i;
}
function objectNameOf(game, i) {
  if (game.objectName) return game.objectName(i);
  return i < game.objectNames.length ? game.objectNames[i] : 'object_extra_' + i;
}

// Said about a problem with the castle rather than with this code, for the
// page to show as it is.
class CastleError extends Error {}

function hex(n, digits) {
  return '$' + n.toString(16).toUpperCase().padStart(digits, '0');
}

// --- snapshots ------------------------------------------------------------

function peek(sna, addr) { return sna[SNA_HEADER + addr - RAM_START]; }
function word(sna, addr) { return peek(sna, addr) | (peek(sna, addr + 1) << 8); }
function peekBytes(sna, addr, count) {
  const at = SNA_HEADER + addr - RAM_START;
  return sna.slice(at, at + count);
}

function z80Unpack(data, size) {
  const out = new Uint8Array(size);
  let at = 0;
  let n = 0;
  while (at < data.length && n < size) {
    if (data[at] === 0xED && data[at + 1] === 0xED) {
      out.fill(data[at + 3], n, n + data[at + 2]);
      n += data[at + 2];
      at += 4;
    } else {
      out[n++] = data[at++];
    }
  }
  if (n !== size) throw new CastleError('a .z80 page unpacked to ' + n + ' bytes, not ' + size);
  return out;
}

// A .z80 of a 48K, versions 1 to 3, as a .sna: the RAM, and the registers
// with PC pushed onto the stack, since that is how a .sna holds it.
function z80ToSna(raw) {
  const ram = new Uint8Array(0xC000);
  let pc = raw[6] | (raw[7] << 8);
  if (pc !== 0) {
    const flags = raw[12] === 0xFF ? 1 : raw[12];
    let body = raw.subarray(30);
    if (flags & 0x20) {
      const n = body.length;
      if (n >= 4 && body[n - 4] === 0 && body[n - 3] === 0xED &&
          body[n - 2] === 0xED && body[n - 1] === 0) body = body.subarray(0, n - 4);
      ram.set(z80Unpack(body, 0xC000));
    } else {
      if (body.length < 0xC000) throw new CastleError('this .z80 is shorter than 48K of RAM');
      ram.set(body.subarray(0, 0xC000));
    }
  } else {
    const extra = raw[30] | (raw[31] << 8);
    const hardware = raw[34];
    const allowed = extra === 23 ? [0, 1] : [0, 1, 3];
    if (allowed.indexOf(hardware) < 0) {
      throw new CastleError('this .z80 is of a 128K; these games want one taken on a 48K');
    }
    pc = raw[32] | (raw[33] << 8);
    const pages = { 8: 0x0000, 4: 0x4000, 5: 0x8000 };      // offsets into RAM
    const seen = new Set();
    let at = 32 + extra;
    while (at + 3 <= raw.length) {
      const length = raw[at] | (raw[at + 1] << 8);
      const page = raw[at + 2];
      at += 3;
      let data;
      if (length === 0xFFFF) {
        data = raw.subarray(at, at + 0x4000);
        at += 0x4000;
      } else {
        data = z80Unpack(raw.subarray(at, at + length), 0x4000);
        at += length;
      }
      if (pages[page] !== undefined) {
        ram.set(data, pages[page]);
        seen.add(page);
      }
    }
    if (seen.size !== 3) throw new CastleError('this .z80 is missing some of a 48K’s RAM');
  }
  const sp = raw[8] | (raw[9] << 8);
  const pushed = (sp - 2) & 0xFFFF;
  if (pushed < RAM_START || pushed > 0xFFFE) throw new CastleError('this .z80’s stack is not in RAM');
  ram[pushed - RAM_START] = pc & 0xFF;
  ram[pushed - RAM_START + 1] = pc >> 8;

  const h = new Uint8Array(SNA_HEADER);
  const lohi = function (at, lo, hi) { h[at] = lo; h[at + 1] = hi; };
  h[0] = raw[10];                                      // I
  lohi(1, raw[19], raw[20]);                           // HL'
  lohi(3, raw[17], raw[18]);                           // DE'
  lohi(5, raw[15], raw[16]);                           // BC'
  lohi(7, raw[22], raw[21]);                           // F', A'
  lohi(9, raw[4], raw[5]);                             // HL
  lohi(11, raw[13], raw[14]);                          // DE
  lohi(13, raw[2], raw[3]);                            // BC
  lohi(15, raw[23], raw[24]);                          // IY
  lohi(17, raw[25], raw[26]);                          // IX
  h[19] = raw[28] ? 0x04 : 0x00;                       // IFF2
  h[20] = (raw[11] & 0x7F) | ((raw[12] & 1) << 7);     // R
  lohi(21, raw[1], raw[0]);                            // F, A
  lohi(23, pushed & 0xFF, pushed >> 8);
  h[25] = raw[29] & 3;                                 // IM
  h[26] = (raw[12] === 0xFF ? 0 : (raw[12] >> 1)) & 7; // border
  const out = new Uint8Array(SNA_SIZE);
  out.set(h);
  out.set(ram, SNA_HEADER);
  return out;
}

// Any snapshot the page takes, as a .sna.
function readSnapshot(bytes, name) {
  // Always a plain Uint8Array of its own: a Node Buffer's slice() is a view,
  // and a build that wrote through one would patch the original it started
  // from.
  const raw = Uint8Array.from(bytes);
  const kind = String(name || '').toLowerCase().split('.').pop();
  if (kind === 'sna') {
    if (raw.length !== SNA_SIZE) {
      throw new CastleError('that .sna is ' + raw.length + ' bytes; a 48K one is ' + SNA_SIZE);
    }
    return raw;
  }
  if (kind === 'z80') return z80ToSna(raw);
  throw new CastleError('that is not a snapshot: give a .sna or a .z80 of the game');
}

// What is wrong with taking this snapshot for this game, or an empty list:
// the operands name the game's tables where it has them, and the room walk
// lands exactly on the table after the rooms. Anything else -- another game,
// another release, a copy already patched -- is not taken apart.
function originalProblems(sna, game) {
  const wrong = [];
  const want = function (addr, value) {
    if (word(sna, addr) !== value) {
      wrong.push(hex(addr, 4) + ' holds ' + hex(word(sna, addr), 4) + ', not ' + hex(value, 4));
    }
  };
  for (const table of ['rooms', 'objectTable', 'sceneryTable']) {
    for (const addr of game.operands[table]) want(addr, game.original[table]);
  }
  if (wrong.length) return wrong;
  const end = game.original[game.after[0]];
  let p = game.original.rooms;
  while (p < end) p += peek(sna, p + 1) + 1;
  if (p !== end) wrong.push('the room walk ends at ' + hex(p, 4) + ', not ' + hex(end, 4));
  return wrong;
}

// Which game a snapshot is, as its profile, or why none.
function identify(sna) {
  for (const game of GAMES) {
    if (!originalProblems(sna, game).length) return game;
  }
  throw new CastleError('This is not an original copy of ' +
    GAMES.map(function (g) { return g.title; }).join(' or ') + ' that the editor knows.');
}

function checkOriginal(sna, game) {
  const wrong = originalProblems(sna, game || KNIGHT_LORE);
  if (wrong.length) {
    throw new CastleError('This does not look like the original ' + (game || KNIGHT_LORE).title +
                          ': ' + wrong.join('; '));
  }
}

// Whether a snapshot is one this editor has already changed: the operands
// name somewhere else, but the tables still hold together from there.
function patchedGame(sna) {
  for (const game of GAMES) {
    const rooms = word(sna, game.operands.rooms[0]);
    if (rooms > game.roomSizes && rooms < game.regionEnd && (rooms - game.roomSizes) % 3 === 0 &&
        word(sna, game.operands.objectTable[0]) < game.regionEnd &&
        word(sna, game.operands.sceneryTable[0]) < game.regionEnd) return game;
  }
  return null;
}

// --- the artwork ----------------------------------------------------------

function reverseBits(byte) {
  let out = 0;
  for (let bit = 0; bit < 8; bit++) if (byte & (1 << bit)) out |= 0x80 >> bit;
  return out;
}

// The sprite records the way the tape holds them. The games turn a sprite in
// place as they draw it -- left to right, and in Pentagram upside down too --
// and record which way round it is in its width byte, so a snapshot taken
// after they have drawn a few has some turned; original.py's unmirror, record
// by record, on a copy.
function unmirroredRam(sna, game) {
  const ram = sna.slice(SNA_HEADER);
  const lr = game.sprites.leftRight;
  const ud = game.sprites.upsideDown;
  for (const [start, end] of game.sprites.runs) {
    let p = start;
    while (p < end) {
      const at = p - RAM_START;
      const width = ram[at] & 0x1F;
      const height = ram[at + 1];
      // An empty record is a header and nothing else: Knight Lore has six, 0
      // by 0, at $7D98, holes in its numbering.
      const flags = width && height ? ram[at] & (lr | ud) : 0;
      if (flags) {
        const stride = 2 * width;
        const rows = [];
        for (let r = 0; r < height; r++) rows.push(Array.from(ram.subarray(at + 2 + r * stride, at + 2 + (r + 1) * stride)));
        if (flags & lr) {
          for (let r = 0; r < height; r++) {
            const turned = [];
            for (let c = width - 1; c >= 0; c--) turned.push(reverseBits(rows[r][2 * c]), reverseBits(rows[r][2 * c + 1]));
            rows[r] = turned;
          }
        }
        if (flags & ud) rows.reverse();
        rows.forEach(function (row, r) { ram.set(row, at + 2 + r * stride); });
        ram[at] &= ~flags & 0xFF;
      }
      p += 2 + width * height * 2;
    }
    if (p !== end) throw new CastleError('the sprite walk ended at ' + hex(p, 4) + ', not ' + hex(end, 4));
  }
  return ram;
}

// Every sprite the sheet names, with the rectangle it has there.
function sheetSprites(sheet) {
  const out = [];
  (function walk(node, path) {
    for (const key of Object.keys((node && node.sprites) || {})) {
      out.push(Object.assign({ name: path.concat([key]).join('.') }, node.sprites[key]));
    }
    for (const group of Object.keys((node && node.group) || {})) {
      walk(node.group[group], path.concat([group]));
    }
  })(sheet, []);
  return out;
}

// The sprite sheet the designer draws with, painted from the snapshot: what
// sprite_sheet.py writes as sprites.png, laid out by the sprites.json the page
// carries. That file is only names and rectangles; every pixel comes from the
// copy of the game it is given. Ink is white, paper black, a data bit under a
// hole in the mask red, and everything else clear -- sheet.py's palette.
//
// Each sprite is found through a graphic number that draws it, and the game's
// own pointer for that number. Its width has to be the rectangle's, and its
// height the rectangle's plus the blank rows the sheet recorded trimming;
// anything else means the carried layout is not this game's, and is refused.
function sheetPixels(sna, sheet, graphics, game) {
  game = game || KNIGHT_LORE;
  const ram = unmirroredRam(sna, game);
  const sprites = sheetSprites(sheet);
  const numberOf = new Map();
  const said = (graphics && graphics.graphics) || {};
  for (const name of Object.keys(said)) {
    const entry = said[name];
    if (typeof entry.sprite === 'string' && !numberOf.has(entry.sprite)) {
      numberOf.set(entry.sprite, entry.number);
    }
  }
  let width = 0;
  let height = 0;
  for (const s of sprites) {
    width = Math.max(width, s.x + s.w + 1);
    height = Math.max(height, s.y + s.h + 1);
  }
  const pixels = new Uint8ClampedArray(width * height * 4);
  const put = function (x, y, rgba) { pixels.set(rgba, (y * width + x) * 4); };
  const INK = [255, 255, 255, 255];
  const PAPER = [0, 0, 0, 255];
  const STRAY = [255, 0, 0, 255];
  const table = game.sprites.table;
  for (const s of sprites) {
    // A sprite no graphic number draws -- Pentagram has three, reached from
    // neither the graphic table nor the code -- is on the sheet for whoever
    // paints it, and never drawn in a room, so it stays blank here.
    const number = numberOf.get(s.name);
    if (number === undefined) continue;
    const at = ram[table + 2 * number - RAM_START] | (ram[table + 2 * number + 1 - RAM_START] << 8);
    if (!game.sprites.runs.some(function (run) { return at >= run[0] && at < run[1]; })) {
      throw new CastleError('graphic ' + number + ' (' + s.name + ') points outside the sprites');
    }
    const w = ram[at - RAM_START] & 0x1F;
    const h = ram[at - RAM_START + 1];
    if (w * 8 !== s.w || h !== s.h + (s.trim || 0)) {
      throw new CastleError('the sprite ' + s.name + ' is ' + w * 8 + ' by ' + h +
                            ' in this copy, which is not what the editor was made for');
    }
    // Stored bottom row first: row r of the picture, counting down from the
    // top, is stored row h - 1 - r, and the trimmed rows are the last few.
    for (let r = 0; r < s.h; r++) {
      const row = at - RAM_START + 2 + (h - 1 - r) * w * 2;
      for (let c = 0; c < w; c++) {
        const mask = ram[row + 2 * c];
        const data = ram[row + 2 * c + 1];
        for (let bit = 0; bit < 8; bit++) {
          const covers = mask & (0x80 >> bit);
          const set = data & (0x80 >> bit);
          const x = s.x + c * 8 + bit;
          if (covers) put(x, s.y + r, set ? INK : PAPER);
          else if (set) put(x, s.y + r, STRAY);
        }
      }
    }
  }
  return { width: width, height: height, pixels: pixels };
}

// The rules a decoded castle states in its meta, for the room designer: the
// limits the original puts on it, and for Alien 8 where it draws and starts.
function rulesFor(game) {
  const rules = { poolLimit: game.pool.limit, shapeLimit: game.attr.shapes,
                  objectTemplateLimit: game.objectLimit };
  if (game.yOrigin !== 296) rules.yOrigin = game.yOrigin;
  if (game.startSpot !== START_SPOT) rules.startSpot = Object.assign({}, game.startSpot);
  if (game.nudgeHeader !== null) rules.groupNudge = true;
  return rules;
}

// --- the castle, decoded --------------------------------------------------

// The graphics that draw something, by number -> name, as graphics.py names():
// a graphic's name is its key in graphics.json.
function graphicNames(graphics) {
  const out = new Map();
  const said = (graphics && graphics.graphics) || {};
  for (const name of Object.keys(said)) {
    if (said[name].sprite !== undefined && said[name].sprite !== null) out.set(said[name].number, name);
  }
  return out;
}

function nameOf(known, number) {
  return known.has(number) ? known.get(number) : 'gfx_' + number.toString(16).toUpperCase().padStart(2, '0');
}

// ...and back, as graphics.py number_of.
function numberOf(known, name, whose) {
  for (const [number, said] of known) if (said === name) return number;
  if (/^gfx_[0-9A-Fa-f]+$/.test(name)) return parseInt(name.slice(4), 16);
  throw new CastleError(whose + ' names the graphic ' + name + ', which graphics.json does not have');
}

function graphicSizes(graphics) {
  const out = new Map();
  const said = (graphics && graphics.graphics) || {};
  for (const name of Object.keys(said)) {
    const box = said[name].size;
    if (box) out.set(name, { u: box.u, v: box.v, z: box.z });
  }
  return out;
}

// The box a template entry occupies the way round it sits: its own if it
// carries one, else its graphic's, U and V swapped when mirrored.
function boxOf(sizes, entry, whose) {
  if (entry.sizeU !== undefined) return { u: entry.sizeU, v: entry.sizeV, z: entry.sizeZ };
  const box = sizes.get(entry.graphic);
  if (!box) throw new CastleError(whose + ' places the graphic ' + entry.graphic + ', which graphics.json gives no size');
  if (entry.flags && entry.flags.mirrored) return { u: box.v, v: box.u, z: box.z };
  return { u: box.u, v: box.v, z: box.z };
}

// The flags byte, named where the game's meaning is known: bit 6 mirrors in
// every game; Knight Lore's bit 1 lets things through, and Pentagram's own bit
// for that is not known, so it says false and keeps the byte whole in `rest`.
function jsonFlags(byte, game) {
  const passable = game.passableBit !== null && Boolean(byte & game.passableBit);
  return {
    mirrored: Boolean(byte & GAME_MIRROR),
    passable: passable,
    rest: byte & ~(GAME_MIRROR | (game.passableBit || 0)) & 0xFF
  };
}

// A template's pieces, as rooms.py writes them and graphics.py fold_sizes
// then leaves them: the box goes, unless it is not the graphic's.
function decodeTemplate(sna, at, stride, known, sizes, game) {
  const out = [];
  for (; peek(sna, at); at += stride) {
    const raw = peekBytes(sna, at, stride);
    const entry = { graphic: nameOf(known, raw[0]) };
    let box;
    if (stride === SCENERY_STRIDE) {
      entry.u = raw[1]; entry.v = raw[2]; entry.z = raw[3];
      box = [raw[4], raw[5], raw[6]];
      entry.flags = jsonFlags(raw[7], game);
    } else {
      box = [raw[1], raw[2], raw[3]];
      entry.flags = jsonFlags(raw[4], game);
      const nudge = stride > 5 ? raw[5] : 0;
      entry.offsets = { halfU: Boolean(nudge & HALF_U), halfV: Boolean(nudge & HALF_V), raiseZ: nudge & RAISE_Z };
    }
    const own = sizes.get(entry.graphic);
    let want = null;
    if (known.has(raw[0]) && own) {
      want = entry.flags.mirrored ? [own.v, own.u, own.z] : [own.u, own.v, own.z];
    }
    if (!want || want[0] !== box[0] || want[1] !== box[1] || want[2] !== box[2]) {
      // Kept on the entry, in the order rooms.py writes them.
      const kept = { graphic: entry.graphic };
      if (stride === SCENERY_STRIDE) { kept.u = entry.u; kept.v = entry.v; kept.z = entry.z; }
      kept.sizeU = box[0]; kept.sizeV = box[1]; kept.sizeZ = box[2];
      kept.flags = entry.flags;
      if (entry.offsets) kept.offsets = entry.offsets;
      out.push(kept);
    } else {
      out.push(entry);
    }
  }
  return out;
}

// A pointer table's length is where its bodies begin: pointers run until the
// lowest one so far is reached. A pointer at the table itself is Pentagram's
// unused slot, not a body, and does not count.
function tableLength(sna, tbl) {
  let lowest = Infinity;
  let i = 0;
  for (; tbl + 2 * i < lowest; i++) {
    const p = word(sna, tbl + 2 * i);
    if (p > tbl) lowest = Math.min(lowest, p);
  }
  return i;
}

// The castle a snapshot holds, as the designer's two files, and Knight Lore's
// specials.json. It reads the tables wherever the operands say they are, so a
// snapshot this editor has already patched can be opened again -- though only
// a pristine one can be built from, which is the caller's to insist on.
function decodeCastle(sna, graphics, game) {
  game = game || KNIGHT_LORE;
  const known = graphicNames(graphics);
  const sizes = graphicSizes(graphics);
  const roomsAt = word(sna, game.operands.rooms[0]);
  const objectTbl = word(sna, game.operands.objectTable[0]);
  const sceneryTbl = word(sna, game.operands.sceneryTable[0]);
  const walkEnd = game.after[0] === 'objectTable' ? objectTbl : sceneryTbl;

  const sceneryTemplates = {};
  for (let i = 0; i < tableLength(sna, sceneryTbl); i++) {
    const at = word(sna, sceneryTbl + 2 * i);
    sceneryTemplates[sceneryNameOf(game, i)] =
      at === sceneryTbl ? [] : decodeTemplate(sna, at, SCENERY_STRIDE, known, sizes, game);
  }
  // A slot is a template's place in its table: the index a header names, and
  // in Alien 8 the page times 32 plus it. Its reserved slots -- 0 and 31 of
  // each page, the nudge and the page switch -- hold zero and are not
  // templates.
  const objectTemplates = {};
  const objectAt = new Map();
  for (let i = 0; i < tableLength(sna, objectTbl); i++) {
    const at = word(sna, objectTbl + 2 * i);
    if (game.pages && (i % game.pages.slots === 0 || i % game.pages.slots === game.pages.slots - 1)) continue;
    const name = objectNameOf(game, i);
    objectTemplates[name] = at === objectTbl ? [] : decodeTemplate(sna, at, game.objectStride, known, sizes, game);
    objectAt.set(i, name);
  }
  const sceneryKeys = Object.keys(sceneryTemplates);

  // The shapes run up to the rooms: a castle given more has moved them.
  const shapeNames = [];
  for (let n = 0; n < (roomsAt - game.roomSizes) / 3; n++) {
    shapeNames.push(n < SHAPE_NAMES.length ? SHAPE_NAMES[n] : 'shape_' + n);
  }

  const rooms = [];
  const shapeMask = game.attr.shapes - 1;
  for (let p = roomsAt; p < walkEnd; p += peek(sna, p + 1) + 1) {
    const number = peek(sna, p);
    const length = peek(sna, p + 1);
    const attr = peek(sna, p + 2);
    const body = Array.from(peekBytes(sna, p + 3, length - 2));
    const scenery = [];
    let i = 0;
    // The scenery runs to an $FF, or to the end of the record: a room with
    // only scenery has no $FF.
    while (i < body.length && body[i] !== SCENERY_END) {
      const ref = { template: sceneryKeys[body[i]] };
      if (game.destinations) { ref.destination = body[i + 1]; i += 2; } else { i += 1; }
      scenery.push(ref);
    }
    i += 1;
    const objects = [];
    // A group asks for its count of positions, but the record's byte count
    // ends the build wherever it runs out: Pentagram's rooms 13 and 108 cut
    // their last group short, and the game builds what is there. In Alien 8 a
    // header of template 0 sets the nudge the groups after it carry, and 31
    // moves to the next page; each is followed by one byte.
    let page = 0;
    let nudge = 0;
    while (i < body.length) {
      const t = (body[i] >> 3) & 0x1F;
      if (game.nudgeHeader !== null && t === 0) { nudge = body[i + 1]; i += 2; continue; }
      if (game.pages && t === 31) { page += 1; i += 2; continue; }
      const count = (body[i] & 7) + 1;
      const group = { template: objectAt.get(game.pages ? page * game.pages.slots + t : t) };
      if (nudge) group.nudge = nudge;
      group.positions = body.slice(i + 1, i + 1 + count).map(function (x) {
        return { u: x & 7, v: (x >> 3) & 7, z: (x >> 6) & 3 };
      });
      objects.push(group);
      i += 1 + count;
    }
    rooms.push({
      number: number,
      ink: (attr >> game.attr.inkShift) & 7,
      dimensions: shapeNames[(attr >> game.attr.shapeShift) & shapeMask],
      scenery: scenery,
      objects: objects
    });
  }
  rooms.sort(function (a, b) { return a.number - b.number; });

  const roomDimensions = {};
  for (let n = 0; n < shapeNames.length; n++) {
    roomDimensions[shapeNames[n]] = {
      u: peek(sna, game.roomSizes + n * 3),
      v: peek(sna, game.roomSizes + n * 3 + 1),
      z: peek(sna, game.roomSizes + n * 3 + 2)
    };
  }

  const castle = {
    rooms: {
      meta: {
        version: 1,
        game: game.id,
        comment: 'Read from the original game by the room editor, which packs it back ' +
                 'into the original’s own tables.',
        sprites: { sheet: 'sprites.png', atlas: 'sprites.json', graphics: 'graphics.json' },
        templates: 'templates.json',
        rules: rulesFor(game)
      },
      roomDimensions: roomDimensions,
      startRooms: Array.from(peekBytes(sna, game.startRooms.at, game.startRooms.count)),
      rooms: rooms
    },
    templates: {
      meta: {
        version: 1,
        game: game.id,
        rooms: 'rooms.json',
        comment: 'The castle’s templates: pieces every room naming one is built from. rooms.json places them.'
      },
      sceneryTemplates: sceneryTemplates,
      objectTemplates: objectTemplates
    },
    specials: null
  };
  if (game.doorways) castle.templates.meta.doorways = Object.assign({}, game.doorways);

  const sp = game.specials;
  if (sp) {
    const collectables = [];
    for (let row = 0; row < sp.rows; row++) {
      const at = sp.table + row * sp.stride;
      collectables.push({ room: peek(sna, at + 4), u: peek(sna, at + 1), v: peek(sna, at + 2), z: peek(sna, at + 3) });
    }
    if (sp.wanted === null) {
      castle.specials = {
        comment: 'The places a valve can lie at the start of a game: U, V, Z and the room from ' +
                 'bytes 1-4 of every nine-byte row of PLACES at $76E3. Which kind each is dealt ' +
                 '-- a valve of one of four, or now and then an extra life -- is the game\u2019s ' +
                 'at every new game.',
        game: game.id,
        rows: sp.rows,
        collectables: collectables
      };
    } else {
      castle.specials = {
        comment: 'The thirty-two collectables: where each one lies at the start of a game, and ' +
                 'the order the wizard asks for them in -- the positions from bytes 1-4 of every ' +
                 'nine-byte row of special_objs_tbl at $6FF2, and the wanted list from ' +
                 'objects_required at $C27D. Which KIND each row is dealt is not here: ' +
                 'special_init deals those at the start of every game.',
        game: game.id,
        collectables: collectables,
        wantedComment: 'The fourteen kinds the wizard wants, in order, each 0 to 7. special_init ' +
                       'turns this list round four to seven places before a game, so the order ' +
                       'here is only where the turning starts.',
        wanted: Array.from(peekBytes(sna, sp.wanted, sp.wantedCount))
      };
    }
  }
  return castle;
}

// What stands where the player starts in a room: the first solid piece whose
// box meets START_SPOT's, as a name to say, or null. The room designer's
// startBlockers makes the same test.
function startBlocker(atlas, room, known, sizes, game) {
  const s = (game || KNIGHT_LORE).startSpot;
  const floorZ = (atlas.roomDimensions[room.dimensions] || {}).z;
  const meets = function (u, v, z, box) {
    return Math.abs(u - s.u) < box.u + s.sizeU && Math.abs(v - s.v) < box.v + s.sizeV &&
           z < s.z + s.sizeZ && z + box.z > s.z;
  };
  const solid = function (entry, whose) {
    return !(entry.flags && entry.flags.passable) &&
           numberOf(known, entry.graphic, whose) >= FIRST_REAL_GRAPHIC;
  };
  for (const ref of room.scenery) {
    for (const entry of atlas.sceneryTemplates[ref.template] || []) {
      if (solid(entry, ref.template) && meets(entry.u, entry.v, entry.z, boxOf(sizes, entry, ref.template))) {
        return ref.template;
      }
    }
  }
  for (const group of room.objects) {
    for (const entry of atlas.objectTemplates[group.template] || []) {
      if (!solid(entry, group.template)) continue;
      const box = boxOf(sizes, entry, group.template);
      const own = entry.offsets || {};
      const g = group.nudge || 0;
      const nudge = { halfU: own.halfU || (g & 1), halfV: own.halfV || (g & 2), raiseZ: (own.raiseZ || 0) + (g & Z_MASK) };
      for (const p of group.positions) {
        const u = p.u * CELL + (nudge.halfU ? HALF_CELL : 0) + CELL_ORIGIN;
        const v = p.v * CELL + (nudge.halfV ? HALF_CELL : 0) + CELL_ORIGIN;
        const z = floorZ + ((p.z * LEVEL_Z + (nudge.raiseZ || 0)) & Z_MASK);
        if (meets(u, v, z, box)) return group.template + ' at ' + p.u + ',' + p.v + ',' + p.z;
      }
    }
  }
  return null;
}

// --- the castle, packed ---------------------------------------------------

function isByte(v) { return Number.isInteger(v) && v >= 0 && v <= 0xFF; }

function flagsByte(flags, game, whose) {
  if (flags.passable && game.passableBit === null) {
    throw new CastleError(whose + ' is marked passable, and ' + game.title +
                          '’s own bit for that is not known');
  }
  return ((flags.mirrored ? GAME_MIRROR : 0) | (flags.passable ? game.passableBit : 0) | flags.rest) & 0xFF;
}

function offsetsByte(o, game, whose) {
  const byte = (o.halfU ? HALF_U : 0) | (o.halfV ? HALF_V : 0) | (o.raiseZ & RAISE_Z);
  if (game.objectStride < 6 && byte) {
    throw new CastleError(whose + ' has a placement nudge, which ' + game.title +
                          '’s object templates have no byte for');
  }
  return byte;
}

// Each template's bytes, zero-terminated, in key order -- which is the index
// a room names it by. An empty one is null: where it points is the game's.
function templateBodies(group, known, sizes, stride, game) {
  const out = new Map();
  for (const name of Object.keys(group)) {
    if (!group[name].length && game.emptyAt === 'table') {
      out.set(name, null);
      continue;
    }
    const bytes = [];
    group[name].forEach(function (entry, n) {
      const whose = name + ', entry ' + (n + 1);
      const number = numberOf(known, entry.graphic, whose);
      if (number === 0) throw new CastleError(whose + ' places graphic 0, the marker that ends a template');
      const box = boxOf(sizes, entry, whose);
      let fields;
      if (stride === SCENERY_STRIDE) {
        fields = [number, entry.u, entry.v, entry.z, box.u, box.v, box.z, flagsByte(entry.flags, game, whose)];
      } else {
        fields = [number, box.u, box.v, box.z, flagsByte(entry.flags, game, whose)];
        const nudge = offsetsByte(entry.offsets || {}, game, whose);
        if (stride > 5) fields.push(nudge);
      }
      if (!fields.every(isByte)) throw new CastleError(whose + ' has a field that is not a byte');
      bytes.push.apply(bytes, fields);
    });
    bytes.push(0);
    out.set(name, bytes);
  }
  return out;
}

// The order to lay bodies out in: the original's, by where its pointer for
// the same index sat, then any template it did not have. That is what gives
// back the game's own bytes for a castle nobody has edited.
function bodyOrder(count, originalPointers) {
  const order = [];
  for (let i = 0; i < count; i++) order.push(i);
  order.sort(function (a, b) {
    const ka = a < originalPointers.length ? [0, originalPointers[a]] : [1, a];
    const kb = b < originalPointers.length ? [0, originalPointers[b]] : [1, b];
    return ka[0] - kb[0] || ka[1] - kb[1];
  });
  return order;
}

// A pointer table at `at` and the bodies after it. A body identical to one
// already laid, or the tail of one, shares it -- the way Pentagram's template
// at $6ABD, with no zero of its own, runs on into the next -- and an empty one
// (null) points at the table itself.
function layTable(at, bodies, order, nullAt) {
  const list = Array.isArray(bodies) ? bodies : Array.from(bodies.values());
  const table = new Array(2 * list.length).fill(0);
  const data = [];
  const ends = [];                      // [start in data, bytes] of each body laid
  for (const i of order) {
    let where = null;
    if (list[i] === null) {
      where = nullAt === undefined ? at : nullAt;
    } else {
      const body = list[i];
      for (const [start, laid] of ends) {
        const tail = laid.length - body.length;
        if (tail >= 0 && body.every(function (b, k) { return laid[tail + k] === b; })) {
          where = at + table.length + start + tail;
          break;
        }
      }
      if (where === null) {
        where = at + table.length + data.length;
        ends.push([data.length, body]);
        data.push.apply(data, body);
      }
    }
    table[2 * i] = where & 0xFF;
    table[2 * i + 1] = where >> 8;
  }
  return table.concat(data);
}

// The castle -- rooms with their templates merged in, as withTemplates makes
// it -- and Knight Lore's specials, against the pristine original: every byte
// a build writes, as [address, bytes] pairs, and how the region was spent.
function packCastle(original, atlas, specials, graphics, game) {
  game = game || KNIGHT_LORE;
  const known = graphicNames(graphics);
  const sizes = graphicSizes(graphics);
  const scenery = templateBodies(atlas.sceneryTemplates, known, sizes, SCENERY_STRIDE, game);
  const objects = templateBodies(atlas.objectTemplates, known, sizes, game.objectStride, game);
  // A group's header holds the template in five bits. In Pentagram 31 is the
  // switch to a second page, not a template; in Alien 8 0 and 31 of each of
  // its two pages are the nudge and the switch.
  if (objects.size > game.objectLimit) {
    throw new CastleError(objects.size + ' object templates; ' + game.title + '\u2019s rooms can name ' +
                          game.objectLimit);
  }
  if (scenery.size >= SCENERY_END) {
    throw new CastleError(scenery.size + ' scenery templates; $FF ends a room’s list, so 255 is the most');
  }
  const sceneryIndex = new Map(Array.from(scenery.keys()).map(function (n, i) { return [n, i]; }));
  // Each object template's slot: its place in the file, or in Alien 8 its
  // page and place on it, 1 to 30.
  const objectIndex = new Map(Array.from(objects.keys()).map(function (n, i) {
    return [n, game.pages ? Math.floor(i / game.pages.perPage) * game.pages.slots + i % game.pages.perPage + 1 : i];
  }));
  const piecesOf = new Map();
  for (const n of Object.keys(atlas.sceneryTemplates)) piecesOf.set(n, atlas.sceneryTemplates[n].length);
  for (const n of Object.keys(atlas.objectTemplates)) piecesOf.set(n, atlas.objectTemplates[n].length);

  // The room sizes, as many as the castle has: the rooms follow them, so a
  // shape more is three bytes more before the rooms, and the operand naming
  // where they start moves with them.
  const shapes = Object.keys(atlas.roomDimensions);
  if (shapes.length < 1 || shapes.length > game.attr.shapes) {
    const bits = ['', 'one', 'two', 'three', 'four', 'five'][Math.round(Math.log2(game.attr.shapes))];
    throw new CastleError(shapes.length + ' floor shapes; a room names one in ' + bits + ' bits, so 1 to ' +
                          game.attr.shapes);
  }
  const region = [];
  for (const s of shapes) {
    const d = atlas.roomDimensions[s];
    for (const field of ['u', 'v', 'z']) {
      const range = SHAPE_RANGE[field];
      if (!Number.isInteger(d[field]) || d[field] < range[0] || d[field] > range[1]) {
        throw new CastleError('the shape ' + s + ': ' + field + ' is ' + range[0] + ' to ' + range[1]);
      }
    }
    region.push(d.u, d.v, d.z);
  }
  const roomsAt = game.roomSizes + region.length;

  const numbers = new Set(atlas.rooms.map(function (r) { return r.number; }));
  const sceneryNames = Array.from(scenery.keys());
  const seen = new Set();
  let fullest = [0, null];
  let roomBytes = 0;
  for (const room of atlas.rooms) {
    const n = room.number;
    const where = 'room ' + hex(n, 2) + ' (' + n + ')';
    if (!isByte(n) || seen.has(n)) throw new CastleError(where + ' is not a room number, or is there twice');
    seen.add(n);
    const shape = shapes.indexOf(room.dimensions);
    if (shape < 0) throw new CastleError(where + ' wants the floor shape ' + room.dimensions + ', which there is not');
    if (!(room.ink >= 0 && room.ink < INKS)) throw new CastleError(where + ' has ink ' + room.ink + '; there are eight');
    const body = [];
    let used = 0;
    for (const ref of room.scenery) {
      if (!sceneryIndex.has(ref.template)) throw new CastleError(where + ' names the scenery template ' + ref.template + ', which there is not');
      const index = sceneryIndex.get(ref.template);
      if (scenery.get(ref.template) === null) {
        throw new CastleError(where + ' places ' + ref.template + ', which has no pieces: the game ' +
                              'would build it out of the template table itself');
      }
      body.push(index);
      if (game.destinations) {
        const to = ref.destination === null || ref.destination === undefined ? 0 : ref.destination;
        if (!isByte(to)) throw new CastleError(where + '’s ' + ref.template + ' leads to ' + to + ', which is not a room number');
        // The walk that finds a room has no end in Pentagram: a doorway to a
        // room that is not there would send it through the rest of memory.
        if (game.isDoorway(index) && !game.walkBounded && !numbers.has(to)) {
          throw new CastleError(where + '’s ' + ref.template + ' leads to room ' + to +
                                ', which there is not; the game would look for it through the rest of memory');
        }
        body.push(to);
      }
      used += piecesOf.get(ref.template);
    }
    if (room.objects.length) body.push(SCENERY_END);
    // In Alien 8 the groups go in page order -- the builder only ever moves
    // on a page -- each page begun with a switch, and a nudge header wherever
    // the next group's nudge differs from the one in force.
    let groups = room.objects;
    if (game.pages) {
      groups = groups.map(function (g, k) { return [g, k]; }).sort(function (a, b) {
        const pa = objectIndex.has(a[0].template) ? Math.floor(objectIndex.get(a[0].template) / game.pages.slots) : 0;
        const pb = objectIndex.has(b[0].template) ? Math.floor(objectIndex.get(b[0].template) / game.pages.slots) : 0;
        return pa - pb || a[1] - b[1];
      }).map(function (pair) { return pair[0]; });
    }
    let page = 0;
    let nudge = 0;
    for (const group of groups) {
      const name = group.template;
      if (!objectIndex.has(name)) throw new CastleError(where + ' names the object template ' + name + ', which there is not');
      if (objects.get(name) === null) {
        throw new CastleError(where + ' places ' + name + ', which has no pieces');
      }
      const spots = group.positions;
      if (spots.length < 1 || spots.length > GROUP_LIMIT) {
        throw new CastleError(where + ' has a group of ' + spots.length + ' ' + name + '; a group holds one to eight');
      }
      const want = group.nudge || 0;
      if (want && game.nudgeHeader === null) {
        throw new CastleError(where + '\u2019s group of ' + name + ' has a nudge of its own, which ' +
                              game.title + '\u2019s rooms have no header for');
      }
      if (!isByte(want)) throw new CastleError(where + '\u2019s group of ' + name + ' has a nudge that is not a byte');
      if (want !== nudge) {
        body.push(game.nudgeHeader, want);
        nudge = want;
      }
      let slot = objectIndex.get(name);
      if (game.pages) {
        const on = Math.floor(slot / game.pages.slots);
        while (page < on) {
          body.push.apply(body, game.pages.escape);
          page += 1;
        }
        slot -= on * game.pages.slots;
      }
      body.push(slot << 3 | (spots.length - 1));
      for (const p of spots) {
        if (!(p.u >= 0 && p.u < CELLS && p.v >= 0 && p.v < CELLS && p.z >= 0 && p.z < LEVELS)) {
          throw new CastleError(where + ' places ' + name + ' off the grid');
        }
        body.push(p.u | p.v << 3 | p.z << 6);
      }
      used += piecesOf.get(name) * spots.length;
    }
    if (!body.length) {
      throw new CastleError(where + ' has nothing in it, which the game’s walk cannot take: ' +
                            'it would read the next room’s record as this one’s');
    }
    if (used > game.pool.limit) {
      throw new CastleError(where + ' fills ' + used + ' object records; the game has ' +
                            game.pool.limit + ' for a room, and one more ' + game.pool.overrun);
    }
    const skip = 2 + body.length;
    if (skip > RECORD_LIMIT) throw new CastleError(where + ' is ' + skip + ' bytes; the skip byte holds 255');
    if (used > fullest[0] || (used === fullest[0] && n > fullest[1])) fullest = [used, n];
    region.push(n, skip, room.ink << game.attr.inkShift | shape << game.attr.shapeShift);
    region.push.apply(region, body);
    roomBytes += 3 + body.length;
  }

  // The two template tables after the rooms, in the game's order, each laid
  // with its bodies in the order the original had them.
  const originalPointers = function (table, count) {
    const out = [];
    for (let i = 0; i < count; i++) out.push(word(original, game.original[table] + 2 * i));
    return out;
  };
  // In Alien 8 the object table is slots: a full page is 32 words, the last
  // page as many as it uses, and the reserved ones hold zero.
  let objectSlots = objects;
  let objectNull;
  if (game.pages) {
    const bodies = Array.from(objects.values());
    const last = bodies.length ? Math.max.apply(null, Array.from(objectIndex.values())) : 0;
    objectSlots = new Array(last + 1).fill(null);
    Array.from(objects.keys()).forEach(function (name, i) { objectSlots[objectIndex.get(name)] = bodies[i]; });
    objectNull = 0;
  }
  const parts = {
    objectTable: { bodies: objectSlots, old: originalPointers('objectTable', game.original.objectCount), nullAt: objectNull },
    sceneryTable: { bodies: scenery, old: originalPointers('sceneryTable', game.original.sceneryCount) }
  };
  const at = {};
  let next = roomsAt + roomBytes;
  const bytesOf = {};
  for (const table of game.after) {
    at[table] = next;
    const bodies = parts[table].bodies;
    const size = Array.isArray(bodies) ? bodies.length : bodies.size;
    const laid = layTable(next, bodies, bodyOrder(size, parts[table].old), parts[table].nullAt);
    bytesOf[table] = laid.length;
    region.push.apply(region, laid);
    next += laid.length;
  }
  const end = next;
  if (end > game.regionEnd) {
    throw new CastleError('the castle needs ' + (end - game.roomSizes) + ' bytes and the original has ' +
                          (game.regionEnd - game.roomSizes) + ': ' + (end - game.regionEnd) + ' too many (rooms ' +
                          roomBytes + ', object templates ' + bytesOf.objectTable + ', scenery templates ' +
                          bytesOf.sceneryTable + ')');
  }
  while (region.length < game.regionEnd - game.roomSizes) region.push(0);

  const writes = [[game.roomSizes, region]];
  const point = function (addrs, value) {
    for (const addr of addrs) writes.push([addr, [value & 0xFF, value >> 8]]);
  };
  point(game.operands.rooms, roomsAt);
  point(game.operands.objectTable, at.objectTable);
  point(game.operands.sceneryTable, at.sceneryTable);

  if (atlas.startRooms !== undefined) {
    const starts = atlas.startRooms;
    const count = game.startRooms.count;
    if (!Array.isArray(starts) || starts.length !== count) {
      const said = ['none', 'one', 'two', 'three', 'four'][count] || String(count);
      throw new CastleError('the game picks one of ' + said + ' starting rooms, and the castle lists ' +
                            (Array.isArray(starts) ? starts.length : 'none'));
    }
    for (const n of starts) {
      if (!seen.has(n)) throw new CastleError('the game can start in room ' + n + ', which is not a room');
      const blocker = startBlocker(atlas, atlas.rooms.find(function (r) { return r.number === n; }), known, sizes, game);
      if (blocker) {
        throw new CastleError('room ' + hex(n, 2) + ' is a starting room, and ' + blocker +
                              ' stands in the middle of the floor, where the player starts');
      }
    }
    writes.push([game.startRooms.at, starts.slice()]);
  }

  const sp = game.specials;
  if (sp && specials) {
    const rows = specials.collectables;
    const wanted = sp.wanted === null ? [] : (specials.wanted || []);
    if (rows.length !== sp.rows || wanted.length !== sp.wantedCount) {
      throw new CastleError('specials has ' + rows.length + ' collectables and ' + wanted.length +
                            ' wanted; the game has ' + sp.rows + ' and ' + sp.wantedCount);
    }
    const table = Array.from(peekBytes(original, sp.table, sp.rows * sp.stride));
    rows.forEach(function (row, i) {
      const fields = [row.u, row.v, row.z, row.room];
      if (!fields.every(isByte)) throw new CastleError('collectable ' + (i + 1) + ' has a field that is not a byte');
      for (let k = 0; k < 4; k++) table[i * sp.stride + 1 + k] = fields[k];
    });
    if (!wanted.every(function (k) { return isByte(k) && k < sp.kinds; })) {
      throw new CastleError('the wanted list holds kinds 0 to ' + (sp.kinds - 1));
    }
    writes.push([sp.table, table]);
    if (sp.wanted !== null) writes.push([sp.wanted, wanted.slice()]);
  }

  return {
    writes: writes,
    report: {
      game: game.id,
      rooms: atlas.rooms.length,
      shapes: shapes.length,
      roomBytes: roomBytes,
      objectBytes: bytesOf.objectTable,
      sceneryBytes: bytesOf.sceneryTable,
      free: game.regionEnd - end,
      fullest: fullest,
      poolLimit: game.pool.limit,
      roomsAt: roomsAt,
      objectTable: at.objectTable,
      sceneryTable: at.sceneryTable,
      blockTypeTbl: at.objectTable,
      backgroundTypeTbl: at.sceneryTable
    }
  };
}

// A copy of the snapshot with every write made; how many bytes it changed.
function applyWrites(sna, writes) {
  const out = sna.slice();
  let changed = 0;
  for (const [addr, bytes] of writes) {
    const at = SNA_HEADER + addr - RAM_START;
    bytes.forEach(function (b, i) {
      if (out[at + i] !== b) changed++;
      out[at + i] = b;
    });
  }
  return { sna: out, changed: changed };
}

function describe(report) {
  return report.rooms + ' rooms in ' + report.roomBytes + ' bytes, ' + report.shapes +
         ' floor shapes, object templates ' +
         report.objectBytes + ', scenery templates ' + report.sceneryBytes + '; ' + report.free +
         ' bytes free. The fullest room is ' + hex(report.fullest[1], 2) + ', at ' +
         report.fullest[0] + ' of ' + report.poolLimit + ' object records.';
}

// The profile a castle names in its meta.
function gameNamed(id) {
  for (const game of GAMES) if (game.id === id) return game;
  throw new CastleError('the editor does not know the game ' + id);
}

// Knight Lore's numbers under the names they had when this was Knight Lore's
// alone, for the tests and knightlore_rooms.py's comparisons.
const POOL_LIMIT = KNIGHT_LORE.pool.limit;
const REGION_END = KNIGHT_LORE.regionEnd;
const ROOM_SIZE_TBL = KNIGHT_LORE.roomSizes;
const BLOCK_TYPE_TBL = KNIGHT_LORE.original.objectTable;
const BACKGROUND_TYPE_TBL = KNIGHT_LORE.original.sceneryTable;
const BLOCK_TYPE_OPERANDS = KNIGHT_LORE.operands.objectTable;
const BACKGROUND_TYPE_OPERANDS = KNIGHT_LORE.operands.sceneryTable;
const LOCATION_OPERAND = KNIGHT_LORE.operands.rooms[0];

if (typeof module !== 'undefined') {
  module.exports = {
    SNA_SIZE, POOL_LIMIT, REGION_END, ROOM_SIZE_TBL, BLOCK_TYPE_TBL, BACKGROUND_TYPE_TBL,
    BLOCK_TYPE_OPERANDS, BACKGROUND_TYPE_OPERANDS, LOCATION_OPERAND,
    GAMES, KNIGHT_LORE, PENTAGRAM, ALIEN8, gameNamed, identify, patchedGame, originalProblems, rulesFor,
    CastleError, readSnapshot, checkOriginal, word, peek,
    sheetPixels, decodeCastle, packCastle, applyWrites, describe, startBlocker
  };
}
