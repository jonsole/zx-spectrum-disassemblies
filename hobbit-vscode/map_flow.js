'use strict';
// The map's layout, flowed out from one place: the player's, or one picked on
// the map. No fixed layout can put every exit of The Hobbit on its own side --
// the game's map contradicts itself (the lonelands' east and north both lead
// to the trolls' clearing), and 30 of its 176 compass exits point the wrong
// way on any layout at all. So the map is laid out afresh around the place
// being looked at, and what is right is what matters there: its own exits
// always point their own way, and the places near it nearly always do. Only
// further out does the map give way where the game's does.
//
// Loaded by the page as a plain script (as MapFlow) and by the tests with
// require: no vscode, no DOM, nothing but the rooms and their exits.

(function (root) {
  /// Where each direction puts the next place: x east, y south. Up and down
  /// have no compass; they go north and south, after the compass exits have
  /// had their pick.
  const STEP = {
    N: [0, -1], S: [0, 1], E: [1, 0], W: [-1, 0],
    NE: [1, -1], NW: [-1, -1], SE: [1, 1], SW: [-1, 1],
    U: [0, -1], D: [0, 1],
  };
  const COMPASS = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
  /// How far along an exit's line a place may be pushed to keep it on the
  /// right side when the cell next door is taken.
  const RAY = 4;

  function key(x, y) {
    return x + ',' + y;
  }

  function sign(v) {
    return v > 0 ? 1 : v < 0 ? -1 : 0;
  }

  /// Every way out of each place, with the way back from the other end for
  /// exits that have none of their own: [{to, direction, step, reverse}].
  /// Its own exits come first, compass before up and down, so they choose
  /// their cells first.
  function neighbours(rooms) {
    const out = new Map();
    for (const r of rooms) {
      out.set(r.location, []);
    }
    const rank = (d) => (COMPASS.includes(d) ? 0 : 1);
    for (const r of rooms) {
      const own = r.exits
        .filter((e) => e.to && e.to !== r.location && out.has(e.to) && STEP[e.direction])
        .sort((a, b) => rank(a.direction) - rank(b.direction));
      for (const e of own) {
        out.get(r.location).push({ to: e.to, direction: e.direction, step: STEP[e.direction], reverse: false });
      }
    }
    // A way back that the game does not give still keeps the two together.
    for (const r of rooms) {
      for (const e of r.exits) {
        if (!e.to || e.to === r.location || !out.has(e.to) || !STEP[e.direction]) {
          continue;
        }
        const back = out.get(e.to);
        if (!back.some((n) => n.to === r.location)) {
          const [dx, dy] = STEP[e.direction];
          back.push({ to: r.location, direction: e.direction, step: [-dx, -dy], reverse: true });
        }
      }
    }
    return out;
  }

  /// The cell for a place reached from `from` along `step`: next door if it
  /// is free, else further along the same line, else the nearest free cell on
  /// the right side, else the nearest free cell at all.
  function cellFor(taken, from, step) {
    const [fx, fy] = from;
    const [sx, sy] = step;
    for (let k = 1; k <= RAY; k++) {
      const x = fx + sx * k;
      const y = fy + sy * k;
      if (!taken.has(key(x, y))) {
        return [x, y];
      }
    }
    const wantX = fx + sx;
    const wantY = fy + sy;
    for (let radius = 1; radius < 40; radius++) {
      let best = null;
      let bestScore = Infinity;
      for (let dx = -radius; dx <= radius; dx++) {
        for (let dy = -radius; dy <= radius; dy++) {
          if (Math.max(Math.abs(dx), Math.abs(dy)) !== radius) {
            continue;
          }
          const x = wantX + dx;
          const y = wantY + dy;
          if (taken.has(key(x, y))) {
            continue;
          }
          const wrong = sign(x - fx) !== sx || sign(y - fy) !== sy ? 1 : 0;
          const score = wrong * 1000 + Math.abs(dx) + Math.abs(dy);
          if (score < bestScore) {
            bestScore = score;
            best = [x, y];
          }
        }
      }
      if (best) {
        return best;
      }
    }
    return [wantX, wantY + 40];
  }

  /// A cell for every place, flowed out from `focus`, which is at [0, 0].
  /// Places the walk never reaches are laid out the same way below the rest.
  function flow(rooms, focus) {
    const links = neighbours(rooms);
    const at = new Map();
    const taken = new Set();
    const put = (location, cell) => {
      at.set(location, cell);
      taken.add(key(cell[0], cell[1]));
    };
    const walk = (start, cell) => {
      put(start, cell);
      const queue = [start];
      while (queue.length) {
        const here = queue.shift();
        for (const n of links.get(here) || []) {
          if (at.has(n.to)) {
            continue;
          }
          put(n.to, cellFor(taken, at.get(here), n.step));
          queue.push(n.to);
        }
      }
    };
    const first = links.has(focus) ? focus : rooms.length ? rooms[0].location : null;
    if (first === null) {
      return at;
    }
    walk(first, [0, 0]);
    for (const r of rooms) {
      if (!at.has(r.location)) {
        let bottom = 0;
        for (const [, y] of at.values()) {
          bottom = Math.max(bottom, y);
        }
        walk(r.location, [0, bottom + 2]);
      }
    }
    return at;
  }

  /// Whether the exit from `a` in `direction` points its own way on `cells`.
  /// Up and down have no way to point, and always do.
  function pointsItsWay(cells, a, b, direction) {
    if (!COMPASS.includes(direction)) {
      return true;
    }
    const [ax, ay] = cells.get(a);
    const [bx, by] = cells.get(b);
    const [sx, sy] = STEP[direction];
    return sign(bx - ax) === sx && sign(by - ay) === sy;
  }

  const api = { STEP, COMPASS, flow, pointsItsWay };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.MapFlow = api;
  }
})(this);
