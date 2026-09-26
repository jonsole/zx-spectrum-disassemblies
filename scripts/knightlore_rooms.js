// Knight Lore's castle, out of a snapshot of the original game and back into
// it, in the browser: the half of knightlore_rooms.py that the standalone room
// editor needs, with no Python and no server.
//
// knightlore_rooms.py is the reference and this follows it function for
// function -- the same limits, the same layout, the same round trip -- so the
// two can be checked against each other (knightlore_rooms_test.js does). What
// it reads and writes is a 48K .sna as bytes; a .z80 is turned into one on the
// way in, so that every build starts from the same kind of file.
//
// Plain functions over Uint8Arrays, no DOM: the page draws the sprite sheet
// from what sheetPixels() returns, and Node runs the test.
'use strict';

const SNA_HEADER = 27;
const SNA_SIZE = SNA_HEADER + 0xC000;
const RAM_START = 0x4000;

const ROOM_SIZE_TBL = 0x6248;
const ROOM_SIZE_LIMIT = 32;             // what bits 3-7 of the attribute byte can name
const LOCATION_TBL = 0x6251;            // where the game has it; a build may move it
// retrieve_screen's LD HL,location_tbl at $D3CC, one past the opcode: the one
// operand naming where the rooms start. The room sizes run up to it, so a
// castle with more shapes moves the rooms down and patches this.
const LOCATION_OPERAND = 0xD3CD;
// A half-size keeps $80 plus and minus it inside a byte; a floor is any height.
const SHAPE_RANGE = { u: [1, 127], v: [1, 127], z: [0, 255] };
const BLOCK_TYPE_TBL = 0x6BD1;          // where the game has it; a build may move it
const BACKGROUND_TYPE_TBL = 0x6CE2;     // likewise
const REGION_END = 0x6FF2;              // exclusive: special_objs_tbl starts here
const ORIGINAL_OBJECT_TEMPLATES = 29;
const ORIGINAL_SCENERY_TEMPLATES = 24;

// The operands that name the two template tables: retrieve_screen's
// LD BC,block_type_tbl at $D3C9, next_fg_obj's LD HL,block_type_tbl at $D461
// and next_bg_obj's LD BC,background_type_tbl at $D42A, one past each opcode.
const BLOCK_TYPE_OPERANDS = [0xD3CA, 0xD462];
const BACKGROUND_TYPE_OPERANDS = [0xD42B];

// The rooms a game can start in: init_start_location picks one of these four
// with the bottom two bits of the seed at $5BA0.
const START_LOCATIONS = 0xD1E2;
const START_LOCATION_COUNT = 4;

// Where Sabreman stands when a game starts: plyr_spr_init_data at $D1A1 puts
// him in the middle of the floor, in a box 5 either way and $17 high.
const START_SPOT = { u: 0x80, v: 0x80, z: 0x80, sizeU: 5, sizeV: 5, sizeZ: 0x17 };
// room_unpack's arithmetic for an object's place, as room_model.js has it.
const CELL = 16;
const CELL_ORIGIN = 72;
const HALF_CELL = 8;
const LEVEL_Z = 12;
const Z_MASK = 0xFC;
const FIRST_REAL_GRAPHIC = 2;               // graphic 1 is a blank the game steps over

const SPECIALS_TBL = 0x6FF2;
const SPECIALS_ROWS = 32;
const SPECIALS_STRIDE = 9;              // bytes 1-4 are U, V, Z and the room
const OBJECTS_REQUIRED = 0xC27D;
const OBJECTS_REQUIRED_COUNT = 14;
const KINDS = 8;

// Thirty-six 32-byte records from $5C88 up to the font at $6108.
const POOL_LIMIT = (0x6108 - 0x5C88) / 32;

const SCENERY_STRIDE = 8;               // graphic, U, V, Z, size U, V, Z, flags
const OBJECT_STRIDE = 6;                // graphic, size U, V, Z, flags, offsets
const SCENERY_END = 0xFF;
const OBJECT_TEMPLATE_LIMIT = 32;
const GROUP_LIMIT = 8;
const CELLS = 8;
const LEVELS = 4;
const INKS = 8;
const RECORD_LIMIT = 255;

const GAME_MIRROR = 0x40;
const GAME_PASSABLE = 0x02;
const HALF_U = 0x01;
const HALF_V = 0x02;
const RAISE_Z = 0xFC;

// The sprites: a table of 256 pointers, and the records from $728C to where
// the code starts. The width byte's bit 6 says the game has mirrored a record
// in place as it drew it.
const SPRITE_TBL = 0x7112;
const SPRITES_START = 0x728C;
const SPRITES_END = 0xAF6C;
const SPRITE_MIRRORED = 0x40;

// The names rooms.py gives the game's templates, in the game's table order.
const SCENERY_NAMES = [
  'arch_n', 'arch_e', 'arch_s', 'arch_w',
  'tree_arch_n', 'tree_arch_e', 'tree_arch_s', 'tree_arch_w',
  'gate_0', 'gate_1', 'gate_2', 'gate_3',
  'walls_0', 'walls_1', 'walls_2',
  'trees_0', 'trees_1', 'trees_2',
  'wizard', 'pot',
  'high_arch_e', 'high_arch_s', 'high_arch_e_base', 'high_arch_s_base'
];
const OBJECT_NAMES = [
  'block', 'fire', 'ball_ud_y', 'rock', 'gargoyle', 'spike', 'chest',
  'table', 'guard_ew', 'ghost', 'fire_ns', 'block_high', 'ball_ud_xy',
  'guard_square', 'block_ew', 'block_ns', 'moveable_block', 'spike_high',
  'spike_ball', 'spike_ball_falling', 'fire_ew', 'dropping_block',
  'collapsing_block', 'ball_bounce', 'ball_ud', 'repel_spell',
  'gate_ud_1', 'gate_ud_2', 'ball_ud_x'
];
// The floor shapes, in room_size_tbl's order: bits 3-4 of the attribute byte.
const SHAPE_NAMES = ['square', 'narrowU', 'narrowV'];

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
      throw new CastleError('this .z80 is of a 128K; Knight Lore wants one taken on a 48K');
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

// That this is Knight Lore with its tables where the disassembly says: the
// three operands name the two template tables, and the room walk lands
// exactly on the first. Anything else -- another release, a copy already
// patched -- is refused rather than taken apart wrongly.
function checkOriginal(sna) {
  const wrong = [];
  for (const addr of BLOCK_TYPE_OPERANDS) {
    if (word(sna, addr) !== BLOCK_TYPE_TBL) {
      wrong.push(hex(addr, 4) + ' holds ' + hex(word(sna, addr), 4) + ', not ' + hex(BLOCK_TYPE_TBL, 4));
    }
  }
  for (const addr of BACKGROUND_TYPE_OPERANDS) {
    if (word(sna, addr) !== BACKGROUND_TYPE_TBL) {
      wrong.push(hex(addr, 4) + ' holds ' + hex(word(sna, addr), 4) + ', not ' + hex(BACKGROUND_TYPE_TBL, 4));
    }
  }
  if (word(sna, LOCATION_OPERAND) !== LOCATION_TBL) {
    wrong.push(hex(LOCATION_OPERAND, 4) + ' holds ' + hex(word(sna, LOCATION_OPERAND), 4) + ', not ' + hex(LOCATION_TBL, 4));
  }
  let p = LOCATION_TBL;
  while (p < BLOCK_TYPE_TBL) p += peek(sna, p + 1) + 1;
  if (p !== BLOCK_TYPE_TBL) wrong.push('the room walk ends at ' + hex(p, 4) + ', not ' + hex(BLOCK_TYPE_TBL, 4));
  if (wrong.length) {
    throw new CastleError('This does not look like the original Knight Lore: ' + wrong.join('; '));
  }
}

// --- the artwork ----------------------------------------------------------

function reverseBits(byte) {
  let out = 0;
  for (let bit = 0; bit < 8; bit++) if (byte & (1 << bit)) out |= 0x80 >> bit;
  return out;
}

// The sprite records the way the tape holds them. The game mirrors a sprite
// in place as it draws it, so a snapshot taken after it has drawn a few has
// some turned round; original.py's unmirror, record by record, on a copy.
function unmirroredRam(sna) {
  const ram = sna.slice(SNA_HEADER);
  let p = SPRITES_START;
  while (p < SPRITES_END) {
    const at = p - RAM_START;
    const width = ram[at] & 0x1F;
    const height = ram[at + 1];
    if (width && height && (ram[at] & SPRITE_MIRRORED)) {
      const stride = 2 * width;
      for (let r = 0; r < height; r++) {
        const row = at + 2 + r * stride;
        const pairs = [];
        for (let c = 0; c < width; c++) pairs.push([ram[row + 2 * c], ram[row + 2 * c + 1]]);
        pairs.reverse();
        for (let c = 0; c < width; c++) {
          ram[row + 2 * c] = reverseBits(pairs[c][0]);
          ram[row + 2 * c + 1] = reverseBits(pairs[c][1]);
        }
      }
      ram[at] &= ~SPRITE_MIRRORED & 0xFF;
    }
    p += 2 + width * height * 2;
  }
  if (p !== SPRITES_END) throw new CastleError('the sprite walk ended at ' + hex(p, 4) + ' -- wrong game?');
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
function sheetPixels(sna, sheet, graphics) {
  const ram = unmirroredRam(sna);
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
  for (const s of sprites) {
    const number = numberOf.get(s.name);
    if (number === undefined) throw new CastleError('no graphic draws the sprite ' + s.name);
    const at = ram[SPRITE_TBL + 2 * number - RAM_START] |
               (ram[SPRITE_TBL + 2 * number + 1 - RAM_START] << 8);
    if (at < SPRITES_START || at >= SPRITES_END) {
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

function jsonFlags(byte) {
  return {
    mirrored: Boolean(byte & GAME_MIRROR),
    passable: Boolean(byte & GAME_PASSABLE),
    rest: byte & ~(GAME_MIRROR | GAME_PASSABLE) & 0xFF
  };
}

// A template's pieces, as rooms.py writes them and graphics.py fold_sizes
// then leaves them: the box goes, unless it is not the graphic's.
function decodeTemplate(sna, at, stride, known, sizes) {
  const out = [];
  for (; peek(sna, at); at += stride) {
    const raw = peekBytes(sna, at, stride);
    const entry = { graphic: nameOf(known, raw[0]) };
    let box;
    if (stride === SCENERY_STRIDE) {
      entry.u = raw[1]; entry.v = raw[2]; entry.z = raw[3];
      box = [raw[4], raw[5], raw[6]];
      entry.flags = jsonFlags(raw[7]);
    } else {
      box = [raw[1], raw[2], raw[3]];
      entry.flags = jsonFlags(raw[4]);
      entry.offsets = { halfU: Boolean(raw[5] & HALF_U), halfV: Boolean(raw[5] & HALF_V), raiseZ: raw[5] & RAISE_Z };
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

// The castle a snapshot holds, as the designer's two files and specials.json.
// It reads the tables wherever the operands say they are, so a snapshot this
// editor has already patched can be opened again -- though only a pristine
// one can be built from, which is the caller's to insist on.
function decodeCastle(sna, graphics) {
  const known = graphicNames(graphics);
  const sizes = graphicSizes(graphics);
  const blockTbl = word(sna, BLOCK_TYPE_OPERANDS[0]);
  const backgroundTbl = word(sna, BACKGROUND_TYPE_OPERANDS[0]);
  // A table's length is where its bodies begin: pointers run until the
  // lowest one so far is reached.
  const countOf = function (tbl) {
    let lowest = Infinity;
    let i = 0;
    for (; tbl + 2 * i < lowest; i++) lowest = Math.min(lowest, word(sna, tbl + 2 * i));
    return i;
  };
  const objectCount = countOf(blockTbl);
  const sceneryCount = countOf(backgroundTbl);
  const templateName = function (names, prefix, i) {
    return prefix + (i < names.length ? names[i] : 'extra_' + i);
  };

  const sceneryTemplates = {};
  for (let i = 0; i < sceneryCount; i++) {
    sceneryTemplates[templateName(SCENERY_NAMES, 'scenery_', i)] =
      decodeTemplate(sna, word(sna, backgroundTbl + 2 * i), SCENERY_STRIDE, known, sizes);
  }
  const objectTemplates = {};
  for (let i = 0; i < objectCount; i++) {
    objectTemplates[templateName(OBJECT_NAMES, 'object_', i)] =
      decodeTemplate(sna, word(sna, blockTbl + 2 * i), OBJECT_STRIDE, known, sizes);
  }
  const sceneryKeys = Object.keys(sceneryTemplates);
  const objectKeys = Object.keys(objectTemplates);

  const rooms = [];
  // The rooms start wherever the operand says, and the sizes run up to them:
  // a castle this editor has given more shapes has moved both.
  const locationTbl = word(sna, LOCATION_OPERAND);
  const shapeNames = [];
  for (let n = 0; n < (locationTbl - ROOM_SIZE_TBL) / 3; n++) {
    shapeNames.push(n < SHAPE_NAMES.length ? SHAPE_NAMES[n] : 'shape_' + n);
  }
  for (let p = locationTbl; p < blockTbl; p += peek(sna, p + 1) + 1) {
    const number = peek(sna, p);
    const length = peek(sna, p + 1);
    const attr = peek(sna, p + 2);
    const body = Array.from(peekBytes(sna, p + 3, length - 2));
    const cut = body.indexOf(SCENERY_END);
    const sceneryIds = cut < 0 ? body : body.slice(0, cut);
    const objectBytes = cut < 0 ? [] : body.slice(cut + 1);
    const objects = [];
    for (let i = 0; i < objectBytes.length;) {
      const count = (objectBytes[i] & 7) + 1;
      objects.push({
        template: objectKeys[(objectBytes[i] >> 3) & 0x1F],
        positions: objectBytes.slice(i + 1, i + 1 + count).map(function (x) {
          return { u: x & 7, v: (x >> 3) & 7, z: (x >> 6) & 3 };
        })
      });
      i += 1 + count;
    }
    rooms.push({
      number: number,
      ink: attr & 7,
      dimensions: shapeNames[attr >> 3],
      scenery: sceneryIds.map(function (i) { return { template: sceneryKeys[i] }; }),
      objects: objects
    });
  }
  rooms.sort(function (a, b) { return a.number - b.number; });

  const roomDimensions = {};
  for (let n = 0; n < shapeNames.length; n++) {
    roomDimensions[shapeNames[n]] = {
      u: peek(sna, ROOM_SIZE_TBL + n * 3),
      v: peek(sna, ROOM_SIZE_TBL + n * 3 + 1),
      z: peek(sna, ROOM_SIZE_TBL + n * 3 + 2)
    };
  }

  const collectables = [];
  for (let row = 0; row < SPECIALS_ROWS; row++) {
    const at = SPECIALS_TBL + row * SPECIALS_STRIDE;
    collectables.push({ room: peek(sna, at + 4), u: peek(sna, at + 1), v: peek(sna, at + 2), z: peek(sna, at + 3) });
  }

  return {
    rooms: {
      meta: {
        version: 1,
        game: 'knightlore',
        comment: 'Read from the original game by the Knight Lore room editor, ' +
                 'which packs it back into the original’s own tables.',
        sprites: { sheet: 'sprites.png', atlas: 'sprites.json', graphics: 'graphics.json' },
        templates: 'templates.json',
        rules: { poolLimit: POOL_LIMIT, shapeLimit: ROOM_SIZE_LIMIT }
      },
      roomDimensions: roomDimensions,
      startRooms: Array.from(peekBytes(sna, START_LOCATIONS, START_LOCATION_COUNT)),
      rooms: rooms
    },
    templates: {
      meta: {
        version: 1,
        game: 'knightlore',
        rooms: 'rooms.json',
        comment: 'The castle’s templates: pieces every room naming one is built from. rooms.json places them.'
      },
      sceneryTemplates: sceneryTemplates,
      objectTemplates: objectTemplates
    },
    specials: {
      comment: 'The thirty-two collectables: where each one lies at the start of a game, and ' +
               'the order the wizard asks for them in -- the positions from bytes 1-4 of every ' +
               'nine-byte row of special_objs_tbl at $6FF2, and the wanted list from ' +
               'objects_required at $C27D. Which KIND each row is dealt is not here: ' +
               'special_init deals those at the start of every game.',
      game: 'knightlore',
      collectables: collectables,
      wantedComment: 'The fourteen kinds the wizard wants, in order, each 0 to 7. special_init ' +
                     'turns this list round four to seven places before a game, so the order ' +
                     'here is only where the turning starts.',
      wanted: Array.from(peekBytes(sna, OBJECTS_REQUIRED, OBJECTS_REQUIRED_COUNT))
    }
  };
}

// What stands where Sabreman starts in a room: the first solid piece whose box
// meets START_SPOT's, as a name to say, or null. The room designer's
// startBlockers makes the same test.
function startBlocker(atlas, room, known, sizes) {
  const s = START_SPOT;
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
      const nudge = entry.offsets || {};
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

function flagsByte(flags) {
  return ((flags.mirrored ? GAME_MIRROR : 0) | (flags.passable ? GAME_PASSABLE : 0) | flags.rest) & 0xFF;
}

function offsetsByte(o) {
  return (o.halfU ? HALF_U : 0) | (o.halfV ? HALF_V : 0) | (o.raiseZ & RAISE_Z);
}

function templateBodies(group, known, sizes, stride) {
  const out = new Map();
  for (const name of Object.keys(group)) {
    const bytes = [];
    group[name].forEach(function (entry, n) {
      const whose = name + ', entry ' + (n + 1);
      const number = numberOf(known, entry.graphic, whose);
      if (number === 0) throw new CastleError(whose + ' places graphic 0, the marker that ends a template');
      const box = boxOf(sizes, entry, whose);
      const fields = stride === SCENERY_STRIDE
        ? [number, entry.u, entry.v, entry.z, box.u, box.v, box.z, flagsByte(entry.flags)]
        : [number, box.u, box.v, box.z, flagsByte(entry.flags), offsetsByte(entry.offsets)];
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

// A pointer table at `at` and the bodies after it; identical bodies share one.
function layTable(at, bodies, order) {
  const list = Array.from(bodies.values());
  const table = new Array(2 * list.length).fill(0);
  const data = [];
  const placed = new Map();
  for (const i of order) {
    const key = list[i].join(',');
    if (!placed.has(key)) {
      placed.set(key, at + table.length + data.length);
      data.push.apply(data, list[i]);
    }
    table[2 * i] = placed.get(key) & 0xFF;
    table[2 * i + 1] = placed.get(key) >> 8;
  }
  return table.concat(data);
}

// The castle -- rooms with their templates merged in, as withTemplates makes
// it -- and specials.json, against the pristine original: every byte a build
// writes, as [address, bytes] pairs, and how the region was spent.
function packCastle(original, atlas, specials, graphics) {
  const known = graphicNames(graphics);
  const sizes = graphicSizes(graphics);
  const scenery = templateBodies(atlas.sceneryTemplates, known, sizes, SCENERY_STRIDE);
  const objects = templateBodies(atlas.objectTemplates, known, sizes, OBJECT_STRIDE);
  if (objects.size > OBJECT_TEMPLATE_LIMIT) {
    throw new CastleError(objects.size + ' object templates; a room names one in five bits, which holds 32');
  }
  if (scenery.size >= SCENERY_END) {
    throw new CastleError(scenery.size + ' scenery templates; $FF ends a room’s list, so 255 is the most');
  }
  const sceneryIndex = new Map(Array.from(scenery.keys()).map(function (n, i) { return [n, i]; }));
  const objectIndex = new Map(Array.from(objects.keys()).map(function (n, i) { return [n, i]; }));
  const piecesOf = new Map();
  for (const n of Object.keys(atlas.sceneryTemplates)) piecesOf.set(n, atlas.sceneryTemplates[n].length);
  for (const n of Object.keys(atlas.objectTemplates)) piecesOf.set(n, atlas.objectTemplates[n].length);

  // The room sizes, as many as the castle has: the rooms follow them, so a
  // shape more is three bytes more before the rooms, and the operand naming
  // where they start moves with them.
  const shapes = Object.keys(atlas.roomDimensions);
  if (shapes.length < 1 || shapes.length > ROOM_SIZE_LIMIT) {
    throw new CastleError(shapes.length + ' floor shapes; a room names one in five bits, so 1 to ' +
                          ROOM_SIZE_LIMIT);
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
  const locationTbl = ROOM_SIZE_TBL + region.length;

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
      body.push(sceneryIndex.get(ref.template));
      used += piecesOf.get(ref.template);
    }
    if (room.objects.length) body.push(SCENERY_END);
    for (const group of room.objects) {
      const name = group.template;
      if (!objectIndex.has(name)) throw new CastleError(where + ' names the object template ' + name + ', which there is not');
      const spots = group.positions;
      if (spots.length < 1 || spots.length > GROUP_LIMIT) {
        throw new CastleError(where + ' has a group of ' + spots.length + ' ' + name + '; a group holds one to eight');
      }
      body.push(objectIndex.get(name) << 3 | (spots.length - 1));
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
    if (used > POOL_LIMIT) {
      throw new CastleError(where + ' fills ' + used + ' object records; the game’s table holds ' +
                            POOL_LIMIT + ', and one more overwrites the font and the room tables');
    }
    const skip = 2 + body.length;
    if (skip > RECORD_LIMIT) throw new CastleError(where + ' is ' + skip + ' bytes; the skip byte holds 255');
    if (used > fullest[0] || (used === fullest[0] && n > fullest[1])) fullest = [used, n];
    region.push(n, skip, room.ink | shape << 3);
    region.push.apply(region, body);
    roomBytes += 3 + body.length;
  }

  const oldObjects = [];
  for (let i = 0; i < ORIGINAL_OBJECT_TEMPLATES; i++) oldObjects.push(word(original, BLOCK_TYPE_TBL + 2 * i));
  const oldScenery = [];
  for (let i = 0; i < ORIGINAL_SCENERY_TEMPLATES; i++) oldScenery.push(word(original, BACKGROUND_TYPE_TBL + 2 * i));

  const blockTbl = locationTbl + roomBytes;
  const objectPart = layTable(blockTbl, objects, bodyOrder(objects.size, oldObjects));
  const backgroundTbl = blockTbl + objectPart.length;
  const sceneryPart = layTable(backgroundTbl, scenery, bodyOrder(scenery.size, oldScenery));
  const end = backgroundTbl + sceneryPart.length;
  if (end > REGION_END) {
    throw new CastleError('the castle needs ' + (end - ROOM_SIZE_TBL) + ' bytes and the original has ' +
                          (REGION_END - ROOM_SIZE_TBL) + ': ' + (end - REGION_END) + ' too many (rooms ' +
                          roomBytes + ', object templates ' + objectPart.length + ', scenery templates ' +
                          sceneryPart.length + ')');
  }
  region.push.apply(region, objectPart);
  region.push.apply(region, sceneryPart);
  while (region.length < REGION_END - ROOM_SIZE_TBL) region.push(0);

  const writes = [[ROOM_SIZE_TBL, region], [LOCATION_OPERAND, [locationTbl & 0xFF, locationTbl >> 8]]];
  for (const addr of BLOCK_TYPE_OPERANDS) writes.push([addr, [blockTbl & 0xFF, blockTbl >> 8]]);
  for (const addr of BACKGROUND_TYPE_OPERANDS) writes.push([addr, [backgroundTbl & 0xFF, backgroundTbl >> 8]]);

  if (atlas.startRooms !== undefined) {
    const starts = atlas.startRooms;
    if (!Array.isArray(starts) || starts.length !== START_LOCATION_COUNT) {
      throw new CastleError('the game picks one of four starting rooms, and the castle lists ' +
                            (Array.isArray(starts) ? starts.length : 'none'));
    }
    for (const n of starts) {
      if (!seen.has(n)) throw new CastleError('the game can start in room ' + n + ', which is not a room');
      const blocker = startBlocker(atlas, atlas.rooms.find(function (r) { return r.number === n; }), known, sizes);
      if (blocker) {
        throw new CastleError('room ' + hex(n, 2) + ' is a starting room, and ' + blocker +
                              ' stands in the middle of the floor, where Sabreman starts');
      }
    }
    writes.push([START_LOCATIONS, starts.slice()]);
  }

  if (specials) {
    const rows = specials.collectables;
    const wanted = specials.wanted;
    if (rows.length !== SPECIALS_ROWS || wanted.length !== OBJECTS_REQUIRED_COUNT) {
      throw new CastleError('specials has ' + rows.length + ' collectables and ' + wanted.length +
                            ' wanted; the game has 32 and 14');
    }
    const table = Array.from(peekBytes(original, SPECIALS_TBL, SPECIALS_ROWS * SPECIALS_STRIDE));
    rows.forEach(function (row, i) {
      const fields = [row.u, row.v, row.z, row.room];
      if (!fields.every(isByte)) throw new CastleError('collectable ' + (i + 1) + ' has a field that is not a byte');
      for (let k = 0; k < 4; k++) table[i * SPECIALS_STRIDE + 1 + k] = fields[k];
    });
    if (!wanted.every(function (k) { return isByte(k) && k < KINDS; })) {
      throw new CastleError('the wanted list holds kinds 0 to 7');
    }
    writes.push([SPECIALS_TBL, table]);
    writes.push([OBJECTS_REQUIRED, wanted.slice()]);
  }

  return {
    writes: writes,
    report: {
      rooms: atlas.rooms.length,
      shapes: shapes.length,
      roomBytes: roomBytes,
      objectBytes: objectPart.length,
      sceneryBytes: sceneryPart.length,
      free: REGION_END - end,
      fullest: fullest,
      blockTypeTbl: blockTbl,
      backgroundTypeTbl: backgroundTbl
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
         report.fullest[0] + ' of ' + POOL_LIMIT + ' object records.';
}

if (typeof module !== 'undefined') {
  module.exports = {
    SNA_SIZE, POOL_LIMIT, REGION_END, ROOM_SIZE_TBL, BLOCK_TYPE_TBL, BACKGROUND_TYPE_TBL,
    BLOCK_TYPE_OPERANDS, BACKGROUND_TYPE_OPERANDS, LOCATION_OPERAND,
    CastleError, readSnapshot, checkOriginal, word, peek,
    sheetPixels, decodeCastle, packCastle, applyWrites, describe, startBlocker
  };
}
