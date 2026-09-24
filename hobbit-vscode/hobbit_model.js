'use strict';
// The Hobbit v1.2's state, read out of its memory: the locations, the objects
// and characters and where they are, and the text the game prints -- for
// every character, whether or not the player is there to see it.
//
// Nothing here imports vscode, so it is tested from plain Node. Nothing here
// holds the game's bytes either: every name, exit and number is read from the
// running game. The addresses are the disassembly's, where each is explained:
// https://jonsole.github.io/zx-spectrum-disassemblies/hobbit/

/// Where things are in v1.2.
const ADDR = {
  /// The dictionary. A name is three 12-bit references into it.
  WORD_INDEX: 0x6000,
  /// A 2-byte pointer per location, 0-79 (GET_ROOM).
  ROOM_POINTERS: 0xB9E0,
  /// [number, lo, hi] per object to an $FF (FIND_RECORD's table shape).
  OBJECT_INDEX: 0xC063,
  /// The score, in tenths of a per cent.
  SCORE: 0xB6F7,
  /// Who the sentence being printed is about: 0 the player, else a character.
  ACTING: 0xB6EA,
  /// Non-zero while printing goes to the input window rather than the story.
  INPUT_STYLE: 0xB701,
  /// Every character the game prints passes through here, in A.
  PRINT_CHAR: 0x858B,
  /// What PRINT_GATE lets through: only text that is for real (not an action
  /// being tried out) and that the player is there to see.
  DOING_IT: 0xB6FA,
  PRINTING_ON: 0xB702,
  /// PRINT_WORD_9: a word's letters are about to be printed. The space before
  /// a word is printed only after text that reached the screen (MID_LINE), so
  /// text nobody sees comes without them, and this is where to put them back.
  WORD_START: 0x7567,
  /// PRINT_WORD's CALL NEW_LINE when a word will not fit on the screen's line:
  /// a break in the picture of the text, not in the text.
  WORD_WRAP: 0x7558,
  /// The sentence patterns, 8 bytes each: an action code's words.
  ACTION_PATTERNS: 0xAB53,
  /// The characters' slots, 7 bytes each to an $FF: who, a limit, the script
  /// step it has got to, its table of scripts, and its orders.
  CHARACTERS: 0xCACB,
  /// The timers, 7 bytes each to an $FF: its length, its count (0 when not
  /// running), the routine it runs at the end, how many turns before that it
  /// warns, and the routine it warns with.
  TIMERS: 0xCA84,
};
const CHARACTER_SIZE = 7;
const TIMER_SIZE = 7;
/// The slots empty at the start, and whose they become when the story brings
/// them in: the butler at Beorn's house, the dragon and Bard at the elvenking's
/// cellar (the disassembly's ARRIVAL_HOOKS).
const LATE_ARRIVALS = { 0xCAE7: 0x42, 0xCAFC: 0x46, 0xCB03: 0x3C };

const ROOM_COUNT = 0x50;
const ROOM_HEAD = 10;
const OBJECT_HEAD = 16;
const LETTERS = ' ABCDEFGHIJKLMNOPQRSTUVWXYZ';
/// Exit direction codes, which are also the action codes 1-10.
const DIRECTIONS = [null, 'N', 'S', 'E', 'W', 'NE', 'NW', 'SE', 'SW', 'U', 'D'];
/// Object flag bits (byte 7), highest first, with a letter for the table.
const FLAGS = [
  [0x80, 'v', 'visible: there to be seen and reached'],
  [0x40, 'c', 'a character'],
  [0x20, 'o', 'open, or can be seen into'],
  [0x10, '*', 'gives light'],
  [0x08, 'x', 'dead, or broken'],
  [0x04, 'f', 'full'],
  [0x02, 'l', 'a liquid'],
  [0x01, 'k', 'locked'],
];

/// The memory the model needs, as [start, end) ranges: the dictionary once,
/// and the rest -- variables, rooms, objects -- every time it looks.
const DICTIONARY_RANGE = [0x6000, 0x7000];
const STATE_RANGE = [0xB6E0, 0xCC00];
/// Everything the model reads, for the host to fetch: the dictionary, the
/// action patterns, and the variables, rooms, objects, scripts and timers.
const READ_RANGES = [DICTIONARY_RANGE, [0xAB50, 0xAD30], STATE_RANGE];

function word(mem, at) {
  return mem[at] | (mem[at + 1] << 8);
}

/// The word a 12-bit reference names, expanded the way PRINT_WORD does: a
/// letter a byte, in the low five bits, ending at a zero or at a byte with
/// bit 7 set -- except that bit 7 on the second letter, and on the third when
/// the one before it had it too, do not end the word.
function wordAt(mem, reference) {
  const offset = reference & 0x0FFF;
  if (!offset) {
    return null;
  }
  let address = ADDR.WORD_INDEX + offset;
  let letters = '';
  while (letters.length < 16) {
    const byte = mem[address];
    address++;
    const code = byte & 0x1F;
    if (!code) {
      break;
    }
    letters += code < LETTERS.length ? LETTERS[code] : '?';
    if (byte & 0x80) {
      if (letters.length === 2) {
        continue;
      }
      if (letters.length === 3 && (mem[address - 2] & 0x80)) {
        continue;
      }
      break;
    }
  }
  return letters.toLowerCase();
}

/// A room's or an object's name: the adjectives in the order stored, then the
/// noun, which is stored first -- the game's own order ("round green door").
function nameAt(mem, start) {
  const noun = wordAt(mem, word(mem, start));
  const adjectives = [wordAt(mem, word(mem, start + 2)), wordAt(mem, word(mem, start + 4))];
  const parts = [];
  for (const w of adjectives) {
    if (w) {
      parts.push(w);
    }
  }
  if (noun) {
    parts.push(noun);
  }
  return parts.join(' ');
}

/// Every location but 0, which is a placeholder, not a room.
function readRooms(mem) {
  const rooms = [];
  for (let location = 1; location < ROOM_COUNT; location++) {
    const start = word(mem, ADDR.ROOM_POINTERS + 2 * location);
    const exits = [];
    let at = start + ROOM_HEAD;
    // A record's exits end at $FF; the bound is only a guard against reading
    // something that is not The Hobbit.
    for (let i = 0; i < 16 && mem[at] !== 0xFF; i++, at += 3) {
      exits.push({ direction: DIRECTIONS[mem[at]] || '?', via: mem[at + 1], to: mem[at + 2] });
    }
    rooms.push({
      location,
      name: nameAt(mem, start + 2),
      lit: (mem[start] & 0x80) !== 0,
      visited: (mem[start] & 0x40) !== 0,
      exits,
    });
  }
  return rooms;
}

/// Every object, characters and the player included, in index order.
function readObjects(mem) {
  const objects = [];
  for (let at = ADDR.OBJECT_INDEX; mem[at] !== 0xFF && objects.length < 128; at += 3) {
    const number = mem[at];
    const start = word(mem, at + 1);
    const listed = mem[start];
    const locations = [];
    for (let i = 0; i < listed && i < 8; i++) {
      locations.push(mem[start + OBJECT_HEAD + i]);
    }
    const flags = mem[start + 7];
    objects.push({
      number,
      name: number === 0 ? 'you' : nameAt(mem, start + 8),
      locations,
      holder: mem[start + 1],
      size: mem[start + 2],
      weight: mem[start + 3],
      placed: mem[start + 4],
      strength: mem[start + 5],
      defence: mem[start + 6],
      flags,
      character: (flags & 0x40) !== 0 || number === 0,
    });
  }
  return objects;
}

/// Byte 7 as the table shows it: a letter per bit that is set, '.' per bit
/// that is not, highest first.
function flagLetters(flags) {
  let out = '';
  for (const [bit, letter] of FLAGS) {
    out += flags & bit ? letter : '.';
  }
  return out;
}

/// What the flags mean, in words, for a tooltip.
function flagWords(flags) {
  const out = [];
  for (const [bit, , meaning] of FLAGS) {
    if (flags & bit) {
      out.push(meaning);
    }
  }
  return out.join('; ');
}

/// Where an object is, in words: inside or held by something, or at a place.
function whereIs(object, byNumber, roomsByLocation) {
  if (object.holder !== 0xFF) {
    const holder = byNumber.get(object.holder);
    const who = holder ? holder.name : 'object ' + object.holder;
    return (holder && holder.character ? 'carried by ' : 'in ') + who;
  }
  if (object.locations.length === 0 || object.locations[0] === 0) {
    return 'nowhere';
  }
  const names = object.locations.map((l) => {
    const room = roomsByLocation.get(l);
    return room ? room.name : 'location ' + l;
  });
  return names.join(' / ');
}

/// The location an object is really at: its own, or its holder's, climbing
/// out through whatever holds that. 0 for nowhere.
function locationOf(object, byNumber) {
  let o = object;
  for (let depth = 0; depth < 8 && o; depth++) {
    if (o.holder === 0xFF) {
      return o.locations.length ? o.locations[0] : 0;
    }
    o = byNumber.get(o.holder);
  }
  return 0;
}

/// The sentence an action code stands for -- TAKE, GO NORTH -- from its
/// pattern: up to three words, and for the ten directions the direction first.
function actionSentence(mem, code) {
  const start = ADDR.ACTION_PATTERNS - 8 + 8 * code;
  const words = [];
  for (const k of [0, 2, 4]) {
    const reference = word(mem, start + k);
    if (reference & 0x0FFF) {
      words.push(wordAt(mem, reference));
    }
  }
  if (code >= 1 && code <= 10) {
    words.unshift(wordAt(mem, word(mem, start + 6)));
  }
  return words.filter((w) => w).join(' ');
}

/// One step of a character's script, as CHARACTERS_ACT reads it, in words.
/// The low four bits are the opcode: 0-3 an action with objects, or with
/// bit 0 a routine; 4 an action with none, or a pause for $FF; $0C switch to a
/// script by key, $0E go to, $0F switch at random; anything else back to the
/// first script. Bit 4 adds a fallback, bit 5 ends the character's part on
/// success, bit 6 keeps an order from interrupting. A routine is given by its
/// address, for the host to name from the debug info.
function describeStep(mem, address, nameOf) {
  // A jump says nothing about what the character will do: follow it, a few
  // at most, to the step it leads to.
  for (let hops = 0; hops < 4 && (mem[address] & 0x0F) === 0x0E; hops++) {
    address = word(mem, address + 1);
  }
  const op = mem[address];
  const code = op & 0x0F;
  const thing = (n) => (n === 0xFF ? null : n === 0 ? 'you' : nameOf(n));
  const step = { address, text: '', routine: null };
  if (code < 4 && (code & 1)) {
    step.routine = word(mem, address + 1);
    step.text = 'runs a routine';
  } else if (code < 4) {
    const objects = [thing(mem[address + 2]), thing(mem[address + 3])].filter((o) => o);
    step.text = actionSentence(mem, mem[address + 1]) + (objects.length ? ': ' + objects.join(', ') : '');
  } else if (code === 4) {
    step.text = mem[address + 1] === 0xFF ? 'nothing: a pause' : actionSentence(mem, mem[address + 1]);
  } else if (code === 0x0E) {
    step.text = 'goes on to another part of its script';
  } else if (code === 0x0F) {
    step.text = 'picks one of its first ' + mem[address + 1] + ' scripts at random';
  } else if (code === 0x0C) {
    step.text = 'switches to its script for ' + actionSentence(mem, mem[address + 1]);
  } else {
    step.text = 'goes back to its first script';
  }
  const notes = [];
  if (op & 0x40) {
    notes.push('an order cannot interrupt it');
  }
  if (op & 0x20) {
    notes.push('then its part in the story is over');
  }
  step.notes = notes;
  return step;
}

/// Every character's slot: who, whether they are in the story, the script
/// step they will take next, and how many of the player's orders they will
/// take at once (byte 6: Thorin 6, the goblins none). A slot is empty before
/// the story brings its owner in -- the three LATE_ARRIVALS -- and after a
/// character's part is over, when who it was is gone with it.
function readCharacters(mem, nameOf) {
  const out = [];
  for (let at = ADDR.CHARACTERS; mem[at] !== 0xFF && out.length < 32; at += CHARACTER_SIZE) {
    const number = mem[at] || LATE_ARRIVALS[at] || null;
    const slot = { slot: at, number, inStory: mem[at] !== 0, takesOrders: mem[at + 6] };
    if (slot.inStory) {
      slot.next = describeStep(mem, word(mem, at + 2), nameOf);
    }
    out.push(slot);
  }
  return out;
}

/// Every timer: whether it is running, the turns left, and the routines it
/// runs at the end and to warn.
function readTimers(mem) {
  const out = [];
  for (let at = ADDR.TIMERS; mem[at] !== 0xFF && out.length < 32; at += TIMER_SIZE) {
    out.push({
      index: out.length,
      length: mem[at],
      left: mem[at + 1],
      routine: word(mem, at + 2),
      warnAt: mem[at + 4],
      warnRoutine: mem[at + 4] ? word(mem, at + 5) : null,
    });
  }
  return out;
}

/// Whether the memory looks like The Hobbit v1.2 at all: object 0, the
/// player, is the first entry in the object index, where v1.2 keeps it.
function isHobbit(mem) {
  return mem[ADDR.OBJECT_INDEX] === 0 && word(mem, ADDR.OBJECT_INDEX + 1) === 0xC11B;
}

/// The whole state, as the page draws it.
function readState(mem) {
  if (!isHobbit(mem)) {
    return null;
  }
  const rooms = readRooms(mem);
  const objects = readObjects(mem);
  const byNumber = new Map(objects.map((o) => [o.number, o]));
  const roomsByLocation = new Map(rooms.map((r) => [r.location, r]));
  for (const o of objects) {
    o.where = whereIs(o, byNumber, roomsByLocation);
    o.at = locationOf(o, byNumber);
    o.flagText = flagLetters(o.flags);
    o.flagTitle = flagWords(o.flags);
  }
  const player = byNumber.get(0);
  const nameOf = (n) => (byNumber.has(n) ? byNumber.get(n).name : 'object ' + n);
  return {
    score: word(mem, ADDR.SCORE),
    playerAt: player ? player.at : 0,
    rooms,
    objects,
    characters: readCharacters(mem, nameOf),
    timers: readTimers(mem),
  };
}

/// The logpoints the log is built from. At PRINT_CHAR: the character, who
/// the sentence is about, which window it is going to, and the two flags
/// PRINT_GATE decides by. Where a word starts and where the screen wraps, a
/// marker the assembler knows.
const LOG_MESSAGE = '{A} {(0xB6EA)} {(0xB701)} {(0xB6FA)} {(0xB702)}';
const WORD_MARK = 'word';
const WRAP_MARK = 'wrap';
const LOGPOINTS = [
  { address: ADDR.PRINT_CHAR, message: LOG_MESSAGE },
  { address: ADDR.WORD_START, message: WORD_MARK },
  { address: ADDR.WORD_WRAP, message: WRAP_MARK },
];

/// Turns logpoint reports into lines of the story, each with who it was
/// about and what kind of line it is:
///
///   shown       printed, and on the screen
///   unseen      done for real, but where the player is not there to see it
///   considered  only tried: the game runs an action as a test (DOING_IT
///               clear) to see whether it would work, and what it would have
///               said passes through PRINT_CHAR all the same
///
/// The game builds every character's sentences whether or not the player can
/// see them, and they all pass through PRINT_CHAR -- which is how Wilderland
/// shows what goes on unseen, and how this does too.
class LogAssembler {
  constructor(limit) {
    this.limit = limit || 1000;
    this.lines = [];
    this.current = null;
    this.wrapping = false;
  }

  /// Takes a batch of report texts; returns the lines they finished.
  push(texts) {
    const finished = [];
    for (const text of texts) {
      if (text === WORD_MARK) {
        // A word is starting: after text, it wants a space -- which the game
        // has already printed if the text before it reached the screen.
        if (this.current && this.current.text && !this.current.text.endsWith(' ')) {
          this.current.text += ' ';
        }
        continue;
      }
      if (text === WRAP_MARK) {
        this.wrapping = true;
        continue;
      }
      const parts = text.split(' ');
      if (parts.length < 3) {
        continue;
      }
      const c = parseInt(parts[0], 16);
      const actor = parseInt(parts[1], 16);
      const inputWindow = parseInt(parts[2], 16) !== 0;
      const doing = parts.length < 5 || parseInt(parts[3], 16) !== 0;
      const printing = parts.length < 5 || parseInt(parts[4], 16) !== 0;
      // What goes to the input window is the player's own typing and the
      // game's replies there, which the screen shows anyway.
      if (inputWindow || Number.isNaN(c)) {
        continue;
      }
      if (c === 0x0D && this.wrapping) {
        // The screen's line was full, not the sentence: carry on it.
        this.wrapping = false;
        if (this.current && !this.current.text.endsWith(' ')) {
          this.current.text += ' ';
        }
        continue;
      }
      if (c === 0x0D) {
        if (this.current) {
          finished.push(this.current);
          this.current = null;
        }
        continue;
      }
      if (c < 0x20 || c > 0x7E) {
        continue;
      }
      if (!this.current) {
        this.current = { actor, kind: doing ? (printing ? 'shown' : 'unseen') : 'considered', text: '' };
      }
      this.current.text += String.fromCharCode(c);
    }
    for (const line of finished) {
      this.lines.push(line);
    }
    if (this.lines.length > this.limit) {
      this.lines.splice(0, this.lines.length - this.limit);
    }
    return finished;
  }
}

module.exports = {
  ADDR,
  DICTIONARY_RANGE,
  STATE_RANGE,
  READ_RANGES,
  LOG_MESSAGE,
  LOGPOINTS,
  FLAGS,
  wordAt,
  nameAt,
  readRooms,
  readObjects,
  readState,
  flagLetters,
  flagWords,
  isHobbit,
  actionSentence,
  describeStep,
  readCharacters,
  readTimers,
  LogAssembler,
};
