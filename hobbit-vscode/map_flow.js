'use strict';
// The map's layout around the place being looked at. The map itself is fixed
// -- the site map's layout, map_layout.json -- so it keeps its shape and a
// place stays where you last saw it. But no fixed layout can put every exit
// of The Hobbit on its own side: the game's map contradicts itself (the
// lonelands' east and north both lead to the trolls' clearing), and 30 of its
// 176 compass exits point the wrong way on any layout at all. So around the
// place being looked at -- the player's, or one picked on the map -- the
// layout is adjusted: each of its exits' places is moved into the cell its
// direction names, and whatever was there steps aside into the nearest free
// cell. Only those few places move; the rest of the map stays still.
//
// Loaded by the page as a plain script (as MapFlow) and by the tests with
// require: no vscode, no DOM, nothing but the rooms, their exits and cells.

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
  /// How far along an exit's line a place may be put, when the cells nearer
  /// are held by other exits of the same place.
  const RAY = 3;

  function key(x, y) {
    return x + ',' + y;
  }

  function sign(v) {
    return v > 0 ? 1 : v < 0 ? -1 : 0;
  }

  /// The free cell nearest `cell`, not `cell` itself.
  function nearestFree(occupant, cell) {
    const [cx, cy] = cell;
    for (let radius = 1; radius < 60; radius++) {
      let best = null;
      let bestDistance = Infinity;
      for (let dx = -radius; dx <= radius; dx++) {
        for (let dy = -radius; dy <= radius; dy++) {
          if (Math.max(Math.abs(dx), Math.abs(dy)) !== radius || occupant.has(key(cx + dx, cy + dy))) {
            continue;
          }
          const distance = Math.abs(dx) + Math.abs(dy);
          if (distance < bestDistance) {
            bestDistance = distance;
            best = [cx + dx, cy + dy];
          }
        }
      }
      if (best) {
        return best;
      }
    }
    return [cx, cy + 60];
  }

  /// The layout `base` (location -> [x, y]) with the exits of `focus` put on
  /// their own sides of it. A new Map; `base` is left alone.
  function adjust(rooms, base, focus) {
    const at = new Map();
    const occupant = new Map();
    for (const [location, cell] of base) {
      at.set(location, [cell[0], cell[1]]);
      occupant.set(key(cell[0], cell[1]), location);
    }
    const room = rooms.find((r) => r.location === focus);
    if (!room || !at.has(focus)) {
      return at;
    }
    const move = (location, cell) => {
      const [ox, oy] = at.get(location);
      if (occupant.get(key(ox, oy)) === location) {
        occupant.delete(key(ox, oy));
      }
      at.set(location, cell);
      occupant.set(key(cell[0], cell[1]), location);
    };
    // Compass exits choose first, then up and down; a place reached two ways
    // goes where the first says.
    const rank = (d) => (COMPASS.includes(d) ? 0 : 1);
    const exits = room.exits
      .filter((e) => e.to && e.to !== focus && at.has(e.to) && STEP[e.direction])
      .sort((a, b) => rank(a.direction) - rank(b.direction));
    const settled = new Set([focus]);
    const [fx, fy] = at.get(focus);
    for (const e of exits) {
      if (settled.has(e.to)) {
        continue;
      }
      const [sx, sy] = STEP[e.direction];
      for (let k = 1; k <= RAY; k++) {
        const cell = [fx + sx * k, fy + sy * k];
        const there = occupant.get(key(cell[0], cell[1]));
        if (there === e.to) {
          break;
        }
        if (there !== undefined && settled.has(there)) {
          continue;
        }
        if (there !== undefined) {
          // What was there steps aside, as little as it can.
          move(there, nearestFree(occupant, cell));
        }
        move(e.to, cell);
        break;
      }
      settled.add(e.to);
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

  const api = { STEP, COMPASS, RAY, adjust, pointsItsWay };
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = api;
  } else {
    root.MapFlow = api;
  }
})(this);
