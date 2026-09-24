'use strict';
// The Hobbit Inspector's page: draws what the extension host sends it -- the
// decoded state and the log -- and asks for nothing but a cleared log. All the
// reading of the game happens in the host; the map's adjusting is map_flow.js.

(function () {
  const vscode = acquireVsCodeApi();
  const SVG = 'http://www.w3.org/2000/svg';
  /// A map cell's size in pixels at zoom 100, and a room's box inside it.
  const CELL_W = 104;
  const CELL_H = 48;
  const ROOM_W = 94;
  const ROOM_H = 38;
  /// A colour per character, so the map's dots and the log agree.
  const PALETTE = ['#c0392b', '#8e44ad', '#2980b9', '#16a085', '#d35400', '#7f8c8d', '#27ae60',
                   '#b7950b', '#6c3483', '#1f618d', '#a04000', '#117a65', '#7b241c', '#5d6d7e',
                   '#b03a2e', '#1e8449', '#9a7d0a', '#2e4053'];

  let flagInfo = [];
  let state = null;
  const byNumber = new Map();

  const el = (id) => document.getElementById(id);

  function colourOf(number) {
    return number === 0 ? '#e03030' : PALETTE[number % PALETTE.length];
  }

  function nameOf(number) {
    const o = byNumber.get(number);
    return o ? o.name : 'object ' + number;
  }

  function hex2(n) {
    return n.toString(16).toUpperCase().padStart(2, '0');
  }

  // ---- the log -------------------------------------------------------------

  const logEl = el('log');

  function addLogLines(lines, replace) {
    const atBottom = logEl.scrollTop + logEl.clientHeight >= logEl.scrollHeight - 4;
    if (replace) {
      logEl.textContent = '';
    }
    for (const line of lines) {
      const div = document.createElement('div');
      if (line.kind === 'newgame') {
        div.className = 'line newgame';
        div.textContent = line.text;
        logEl.appendChild(div);
        continue;
      }
      div.className = 'line' + (line.actor === 0 ? ' you' : '') + ' ' + (line.kind || 'shown');
      div.dataset.actor = String(line.actor);
      div.hidden = logWho !== '' && String(line.actor) !== logWho;
      // Only "shown" lines ever reach the screen. The rest the game composes
      // all the same, and this is the only place they are seen.
      const actor = byNumber.get(line.actor);
      const where = actor && actor.at ? ' at ' + roomName(actor.at) : '';
      if (line.kind === 'unseen') {
        div.title = 'Done where the player could not see it' + where;
      } else if (line.kind === 'considered') {
        div.title = 'Only considered: the game tried this out to see whether it would work' + where;
      }
      const who = document.createElement('span');
      who.className = 'who';
      who.textContent = line.actor === 0 ? 'you' : nameOf(line.actor);
      if (line.actor !== 0) {
        who.style.color = colourOf(line.actor);
      }
      div.appendChild(who);
      // The game capitalises as it draws; the text it passes on is lower case.
      div.appendChild(document.createTextNode(line.text.charAt(0).toUpperCase() + line.text.slice(1)));
      logEl.appendChild(div);
    }
    while (logEl.childElementCount > 1000) {
      logEl.removeChild(logEl.firstChild);
    }
    if (atBottom || replace) {
      logEl.scrollTop = logEl.scrollHeight;
    }
  }

  // Only the lines about one character, or everyone's.
  let logWho = '';
  el('log-who').addEventListener('change', () => {
    logWho = el('log-who').value;
    for (const div of logEl.children) {
      if (div.dataset.actor !== undefined) {
        div.hidden = logWho !== '' && div.dataset.actor !== logWho;
      }
    }
  });

  function fillLogWho() {
    const select = el('log-who');
    if (select.options.length > 1) {
      return;
    }
    for (const o of state.objects) {
      if (o.character) {
        const option = document.createElement('option');
        option.value = String(o.number);
        option.textContent = o.number === 0 ? 'you' : o.name;
        select.appendChild(option);
      }
    }
  }

  el('show-considered').addEventListener('change', () => {
    logEl.classList.toggle('hide-considered', !el('show-considered').checked);
  });

  el('clear-log').addEventListener('click', () => {
    logEl.textContent = '';
    vscode.postMessage({ type: 'clearLog' });
  });

  // ---- the objects -----------------------------------------------------------

  function roomName(location) {
    if (!state || !location) {
      return 'nowhere';
    }
    const room = state.rooms.find((r) => r.location === location);
    return room ? room.name : 'location ' + location;
  }

  function drawObjects() {
    const body = el('objects').tBodies[0];
    body.textContent = '';
    for (const o of state.objects) {
      const tr = document.createElement('tr');
      tr.dataset.search = (o.name + ' ' + o.where).toLowerCase();
      if (o.character) {
        tr.classList.add('character');
      }
      if (o.number === 0) {
        tr.classList.add('you');
      }
      if (o.character && (o.flags & 0x08)) {
        tr.classList.add('dead');
      }
      if (o.at && o.at === state.playerAt) {
        tr.classList.add('here');
      }
      const cells = [
        ['num', hex2(o.number)],
        ['name', o.name],
        ['where', o.where],
        ['num', String(o.locations.length)],
        ['num', hex2(o.size)],
        ['num', hex2(o.weight)],
        ['placed', o.placedText],
        ['num', hex2(o.strength)],
        ['num', hex2(o.defence)],
        ['flags', o.flagText],
      ];
      for (const [cls, text] of cells) {
        const td = document.createElement('td');
        td.className = cls;
        td.textContent = text;
        tr.appendChild(td);
      }
      tr.lastChild.title = o.flagTitle || 'no flags';
      if (o.character) {
        tr.children[1].style.color = colourOf(o.number);
      }
      body.appendChild(tr);
    }
    applyFilter();
  }

  function applyFilter() {
    const text = el('filter').value.trim().toLowerCase();
    const hereOnly = el('here-only').checked;
    for (const tr of el('objects').tBodies[0].rows) {
      const show = (!text || tr.dataset.search.includes(text)) && (!hereOnly || tr.classList.contains('here'));
      tr.classList.toggle('hidden', !show);
    }
  }
  el('filter').addEventListener('input', applyFilter);
  el('here-only').addEventListener('change', applyFilter);

  // ---- the characters and the timers ------------------------------------------

  function cell(tr, text, cls) {
    const td = document.createElement('td');
    if (cls) {
      td.className = cls;
    }
    if (text !== undefined) {
      td.textContent = text;
    }
    tr.appendChild(td);
    return td;
  }

  function routineName(address) {
    return (state.names && state.names[address]) || '$' + address.toString(16).toUpperCase();
  }

  function drawCharacters() {
    const body = el('characters').tBodies[0];
    body.textContent = '';
    for (const c of state.characters) {
      const tr = document.createElement('tr');
      const who = c.number === null ? 'gone' : nameOf(c.number);
      const name = cell(tr, who, 'name');
      if (c.number !== null) {
        name.style.color = colourOf(c.number);
      }
      if (!c.inStory) {
        tr.classList.add('idle');
        cell(tr, '');
        cell(tr, c.number === null ? 'its part in the story is over' : 'not in the story yet', 'next');
        cell(tr, '');
        cell(tr, '');
        body.appendChild(tr);
        continue;
      }
      const o = byNumber.get(c.number);
      cell(tr, o ? o.where : '');
      const next = cell(tr, undefined, 'next');
      next.appendChild(document.createTextNode(c.next.text.charAt(0).toUpperCase() + c.next.text.slice(1)));
      if (c.next.routine) {
        const r = document.createElement('span');
        r.className = 'routine';
        r.textContent = ' ' + routineName(c.next.routine);
        next.appendChild(r);
      }
      if (c.next.notes.length) {
        const n = document.createElement('span');
        n.className = 'note';
        n.textContent = ' (' + c.next.notes.join('; ') + ')';
        next.appendChild(n);
      }
      cell(tr, c.carrying.length ? c.carrying.join(', ') : '-', 'next');
      cell(tr, c.takesOrders ? String(c.takesOrders) : 'none', 'num');
      body.appendChild(tr);
    }
  }

  function drawTimers() {
    const body = el('timers').tBodies[0];
    body.textContent = '';
    for (const t of state.timers) {
      const tr = document.createElement('tr');
      tr.classList.add(t.left ? 'running' : 'idle');
      cell(tr, String(t.index), 'num');
      cell(tr, t.left ? t.left + ' of ' + t.length : 'not running', 'left');
      const then = cell(tr, undefined);
      const r = document.createElement('span');
      r.className = 'routine';
      r.textContent = routineName(t.routine);
      then.appendChild(r);
      const warns = cell(tr, undefined);
      if (t.warnRoutine) {
        warns.appendChild(document.createTextNode(t.warnAt + (t.warnAt === 1 ? ' turn' : ' turns') + ' before, '));
        const w = document.createElement('span');
        w.className = 'routine';
        w.textContent = routineName(t.warnRoutine);
        warns.appendChild(w);
      } else {
        warns.textContent = '-';
      }
      body.appendChild(tr);
    }
  }

  for (const tab of document.querySelectorAll('.tab')) {
    tab.addEventListener('click', () => {
      for (const other of document.querySelectorAll('.tab')) {
        other.classList.toggle('selected', other === tab);
        el(other.dataset.tab).hidden = other !== tab;
      }
      for (const extra of document.querySelectorAll('.for-objects-tab')) {
        extra.hidden = tab.dataset.tab !== 'objects-tab';
      }
    });
  }

  // ---- the map ----------------------------------------------------------------

  function svg(tag, attrs, parent) {
    const node = document.createElementNS(SVG, tag);
    for (const k in attrs) {
      node.setAttribute(k, attrs[k]);
    }
    if (parent) {
      parent.appendChild(node);
    }
    return node;
  }

  /// A room's name over at most two lines of the box.
  function wrapName(name) {
    const words = name.split(' ');
    const lines = [''];
    for (const w of words) {
      const cur = lines[lines.length - 1];
      if (cur && (cur + ' ' + w).length > 17 && lines.length < 2) {
        lines.push(w);
      } else {
        lines[lines.length - 1] = cur ? cur + ' ' + w : w;
      }
    }
    return lines;
  }

  // The map is the fixed layout (map_layout.json), adjusted around one place
  // -- the player's, or one clicked on -- so that its exits point their own
  // way (map_flow.js). Only the few places that adjusting moves glide to
  // their new cells; the rest of the map stays still.
  let following = true;
  let focus = 0;
  /// The fixed layout, and the canvas it sits on: its top left cell, and its
  /// size in cells, with room around it for places moved out to the edge.
  let base = null;
  let origin = [0, 0];
  let span = [1, 1];
  /// The layout being shown, as it moves: location -> [x, y] in cells, which
  /// are fractions while it glides.
  let shown = null;
  let target = null;
  let flowFrom = null;
  let flowStart = 0;
  /// The focus the view was last scrolled to, so it scrolls only when the
  /// focus changes, and is otherwise left where the user put it.
  let viewed = -1;
  const FLOW_MS = 450;

  function setBase(cellsByLocation) {
    base = new Map(Object.entries(cellsByLocation).map(([l, c]) => [Number(l), c]));
    const xs = [...base.values()].map((c) => c[0]);
    const ys = [...base.values()].map((c) => c[1]);
    const margin = MapFlow.RAY + 1;
    origin = [Math.min(...xs) - margin, Math.min(...ys) - margin];
    span = [Math.max(...xs) - Math.min(...xs) + 1 + 2 * margin, Math.max(...ys) - Math.min(...ys) + 1 + 2 * margin];
    shown = null;
    target = null;
  }

  function currentFocus() {
    return following ? state.playerAt : focus;
  }

  function sameLayout(a, b) {
    if (!a || a.size !== b.size) {
      return false;
    }
    for (const [loc, [x, y]] of b) {
      const c = a.get(loc);
      if (!c || c[0] !== x || c[1] !== y) {
        return false;
      }
    }
    return true;
  }

  function updateFollowUi() {
    const f = currentFocus();
    el('centred').textContent = following ? 'Centred on you' : 'Centred on ' + f + ': ' + roomName(f);
    el('follow').hidden = following;
  }

  /// Adjusts the map around the current focus, and glides to it if anything moved.
  function relayout() {
    const f = currentFocus();
    updateFollowUi();
    if (!f || !base) {
      return;
    }
    const next = MapFlow.adjust(state.rooms, base, f);
    const now = performance.now();
    if (!sameLayout(target, next)) {
      flowFrom = shown ? new Map(shown) : null;
      target = next;
      if (!flowFrom) {
        shown = new Map(target);
      } else {
        flowStart = now;
        flowing = true;
      }
    }
    if (viewed !== f) {
      centreView(f, viewed !== -1);
      viewed = f;
    }
    if (flowing || scrolling) {
      animate();
    } else {
      drawMap();
    }
  }

  // One animation loop moves the places and the view together, with the same
  // easing, so the map glides as one rather than the boxes and the scroll
  // each going their own way. The scroll is done here, a step a frame, rather
  // than by the browser's smooth scrolling, which it may skip (Windows with
  // animations turned off) and which keeps its own time.
  let flowing = false;
  let scrolling = false;
  let scrollFrom = [0, 0];
  let scrollTo = [0, 0];
  let scrollStart = 0;
  let frameRequested = false;

  function ease(t) {
    return t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
  }

  function animate() {
    if (!frameRequested) {
      frameRequested = true;
      requestAnimationFrame(frame);
    }
  }

  function frame(now) {
    frameRequested = false;
    if (flowing) {
      const t = Math.min(1, (now - flowStart) / FLOW_MS);
      const e = ease(t);
      shown = new Map();
      for (const [loc, [x1, y1]] of target) {
        const from = flowFrom.get(loc) || [x1, y1];
        shown.set(loc, [from[0] + (x1 - from[0]) * e, from[1] + (y1 - from[1]) * e]);
      }
      if (t >= 1) {
        flowing = false;
        shown = new Map(target);
      }
      drawMap();
    }
    if (scrolling) {
      const t = Math.min(1, (now - scrollStart) / FLOW_MS);
      const e = ease(t);
      const scroll = el('map-scroll');
      scroll.scrollLeft = scrollFrom[0] + (scrollTo[0] - scrollFrom[0]) * e;
      scroll.scrollTop = scrollFrom[1] + (scrollTo[1] - scrollFrom[1]) * e;
      if (t >= 1) {
        scrolling = false;
      }
    }
    if (flowing || scrolling) {
      animate();
    }
  }

  // A hand on the map takes the view back from the animation.
  for (const type of ['wheel', 'pointerdown', 'keydown']) {
    el('map-scroll').addEventListener(type, () => {
      scrolling = false;
    }, { passive: true });
  }

  function zoom() {
    return Number(el('zoom').value) / 100;
  }

  function cellCentre(cell) {
    return [(cell[0] - origin[0]) * CELL_W + 4 + CELL_W / 2, (cell[1] - origin[1]) * CELL_H + 4 + CELL_H / 2];
  }

  /// Brings the focus to the middle of the view: gliding there when it moves
  /// from one place to another, at once the first time.
  function centreView(f, smooth) {
    if (!target || !target.has(f)) {
      return;
    }
    if (!smooth) {
      // The first time, the page may not be laid out yet: a frame later it is,
      // and there is something to scroll.
      requestAnimationFrame(() => centreNow(f));
      return;
    }
    const to = scrollTarget(f);
    const scroll = el('map-scroll');
    scrollFrom = [scroll.scrollLeft, scroll.scrollTop];
    scrollTo = to;
    scrollStart = performance.now();
    scrolling = true;
  }

  function centreNow(f) {
    drawMap();
    const [x, y] = scrollTarget(f);
    const scroll = el('map-scroll');
    scroll.scrollLeft = x;
    scroll.scrollTop = y;
    scrolling = false;
  }

  /// The scroll that puts `f` in the middle of the view, as near as the map's
  /// edges allow.
  function scrollTarget(f) {
    const scroll = el('map-scroll');
    const z = zoom();
    const [cx, cy] = cellCentre(target.get(f));
    // Where the scroll can actually reach, so a glide towards the map's edge
    // eases to a stop there rather than being cut off short of it.
    const maxX = Math.max(0, scroll.scrollWidth - scroll.clientWidth);
    const maxY = Math.max(0, scroll.scrollHeight - scroll.clientHeight);
    return [Math.min(maxX, Math.max(0, cx * z - scroll.clientWidth / 2)),
            Math.min(maxY, Math.max(0, cy * z - scroll.clientHeight / 2))];
  }

  /// What stands in the way between two places: the objects their exits pass
  /// through (a door, a gate, a river) that are neither open nor broken --
  /// CAN_PASS lets nobody through otherwise. The game's own exits both ways
  /// count, since a door is the same door from either side.
  function doorsBetween(a, b) {
    const doors = [];
    for (const [from, to] of [[a, b], [b, a]]) {
      const room = state.rooms.find((r) => r.location === from);
      for (const e of room ? room.exits : []) {
        if (e.to !== to || !e.via) {
          continue;
        }
        const o = byNumber.get(e.via);
        if (o && !(o.flags & 0x20) && !(o.flags & 0x08) && !doors.includes(o)) {
          doors.push(o);
        }
      }
    }
    return doors;
  }

  /// A bar across the line from (x1,y1) to (x2,y2), at its middle: a closed
  /// door, or a locked one.
  function drawDoors(parent, x1, y1, x2, y2, doors) {
    if (!doors.length) {
      return;
    }
    const mx = (x1 + x2) / 2;
    const my = (y1 + y2) / 2;
    const length = Math.hypot(x2 - x1, y2 - y1) || 1;
    // Across the line: its direction turned a quarter.
    const nx = -(y2 - y1) / length * 7;
    const ny = (x2 - x1) / length * 7;
    const locked = doors.some((o) => o.flags & 0x01);
    const bar = svg('line', {
      class: 'door' + (locked ? ' locked' : ''),
      x1: mx - nx, y1: my - ny, x2: mx + nx, y2: my + ny,
    }, parent);
    const title = svg('title', {}, bar);
    title.textContent = doors.map((o) => 'the ' + o.name + ': ' + (o.flags & 0x01 ? 'locked' : 'in the way')).join('\n');
  }

  function drawMap() {
    const map = el('map');
    map.textContent = '';
    if (!shown) {
      return;
    }
    const width = span[0] * CELL_W + 8;
    const height = span[1] * CELL_H + 8;
    const z = zoom();
    map.setAttribute('width', String(width * z));
    map.setAttribute('height', String(height * z));
    map.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    // x east, y south: north is up.
    const centre = (location) => cellCentre(shown.get(location));
    const f = currentFocus();

    // Exits first, under the rooms: one line per pair of places, dashed where
    // the way back is not the way there. The focus's own are drawn last, on
    // top, with their directions.
    const exits = svg('g', {}, map);
    const drawn = new Set();
    const doorLines = [];
    const leadsTo = new Map(state.rooms.map((r) => [r.location, new Set(r.exits.map((e) => e.to))]));
    for (const r of state.rooms) {
      if (r.location === f || !shown.has(r.location)) {
        continue;
      }
      for (const e of r.exits) {
        if (!e.to || !shown.has(e.to) || e.to === r.location || e.to === f) {
          continue;
        }
        const key = Math.min(r.location, e.to) + '-' + Math.max(r.location, e.to);
        if (drawn.has(key)) {
          continue;
        }
        drawn.add(key);
        const [x1, y1] = centre(r.location);
        const [x2, y2] = centre(e.to);
        const back = leadsTo.get(e.to);
        svg('line', { class: 'exit' + (back && back.has(r.location) ? '' : ' oneway'), x1, y1, x2, y2 }, exits);
        doorLines.push([x1, y1, x2, y2, doorsBetween(r.location, e.to)]);
      }
    }
    const focusRoom = state.rooms.find((r) => r.location === f);
    const labels = [];
    if (focusRoom && shown.has(f)) {
      // The directions to each place, together where the game gives one
      // place two ways (the lonelands' east and north).
      const ways = new Map();
      for (const e of focusRoom.exits) {
        if (e.to && e.to !== f && shown.has(e.to)) {
          if (!ways.has(e.to)) {
            ways.set(e.to, []);
          }
          ways.get(e.to).push(e.direction);
        }
      }
      const [x1, y1] = centre(f);
      // Ways in with no way back out: drawn, dashed, but not labelled.
      for (const r of state.rooms) {
        if (r.location !== f && shown.has(r.location) && !ways.has(r.location)
            && r.exits.some((e) => e.to === f)) {
          const [x2, y2] = centre(r.location);
          svg('line', { class: 'exit oneway', x1, y1, x2, y2 }, exits);
          doorLines.push([x1, y1, x2, y2, doorsBetween(f, r.location)]);
        }
      }
      for (const [to, directions] of ways) {
        const [x2, y2] = centre(to);
        const back = leadsTo.get(to);
        svg('line', { class: 'exit focus' + (back && back.has(f) ? '' : ' oneway'), x1, y1, x2, y2 }, exits);
        doorLines.push([x1, y1, x2, y2, doorsBetween(f, to)]);
        // The label just outside the focus's box, on its line.
        const dx = x2 - x1;
        const dy = y2 - y1;
        const t = Math.min(dx ? (ROOM_W / 2 + 10) / Math.abs(dx) : Infinity,
                           dy ? (ROOM_H / 2 + 8) / Math.abs(dy) : Infinity, 0.5);
        labels.push([x1 + dx * t, y1 + dy * t, directions.join('/')]);
      }
    }

    // Who and what is where.
    const people = new Map();
    const things = new Map();
    for (const o of state.objects) {
      if (!o.at) {
        continue;
      }
      const list = o.character ? people : things;
      if (!list.has(o.at)) {
        list.set(o.at, []);
      }
      list.get(o.at).push(o);
    }

    for (const r of state.rooms) {
      if (!shown.has(r.location)) {
        continue;
      }
      const [cx, cy] = centre(r.location);
      const g = svg('g', {
        class: 'room' + (r.lit ? '' : ' dark') + (r.visited ? '' : ' unvisited')
          + (r.location === state.playerAt ? ' you' : '') + (r.location === f && !following ? ' focus' : ''),
      }, map);
      const x = cx - ROOM_W / 2;
      const y = cy - ROOM_H / 2;
      svg('rect', { x, y, width: ROOM_W, height: ROOM_H, rx: 3 }, g);
      const here = people.get(r.location) || [];
      const stuff = things.get(r.location) || [];
      const title = svg('title', {}, g);
      title.textContent = r.location + ': ' + r.name + (r.lit ? '' : ' (dark)')
        + (r.visited ? '' : ' (not yet visited)')
        + (here.length ? '\n' + here.map((o) => o.name).join(', ') : '')
        + (stuff.length ? '\nHere: ' + stuff.map((o) => o.name).join(', ') : '')
        + '\nExits: ' + (r.exits.map((e) => {
          const o = e.via ? byNumber.get(e.via) : null;
          const state = !o ? '' : o.flags & 0x01 ? ', locked' : !(o.flags & 0x20) && !(o.flags & 0x08) ? ', in the way' : ', open';
          return e.direction + ' ' + e.to + (o ? ' (through the ' + o.name + state + ')' : '');
        }).join(', ') || 'none')
        + '\nClick to centre the map here';
      const lines = wrapName(r.name);
      lines.forEach((text, i) => {
        const t = svg('text', { x: x + 4, y: y + 12 + i * 10 }, g);
        t.textContent = text;
      });
      const n = svg('text', { class: 'number', x: x + ROOM_W - 4, y: y + ROOM_H - 4, 'text-anchor': 'end' }, g);
      n.textContent = String(r.location);
      // A dot per character, along the bottom of the box.
      here.forEach((o, i) => {
        const dx = x + 7 + i * 11;
        const dy = y + ROOM_H - 7;
        svg('circle', { class: 'who', cx: dx, cy: dy, r: 5, fill: colourOf(o.number) }, g);
        const t = svg('text', { class: 'who', x: dx, y: dy + 2.5, 'text-anchor': 'middle' }, g);
        t.textContent = o.number === 0 ? '@' : o.name.split(' ').pop()[0].toUpperCase();
      });
      g.addEventListener('click', () => {
        following = r.location === state.playerAt;
        focus = r.location;
        relayout();
      });
    }

    // The doors, over the lines and the boxes' edges.
    const doorLayer = svg('g', {}, map);
    for (const [x1, y1, x2, y2, doors] of doorLines) {
      drawDoors(doorLayer, x1, y1, x2, y2, doors);
    }

    // The focus's directions, over everything.
    for (const [lx, ly, text] of labels) {
      const t = svg('text', { class: 'exit-label', x: lx, y: ly + 3, 'text-anchor': 'middle' }, map);
      t.textContent = text;
    }
  }
  el('zoom').addEventListener('input', () => {
    if (state && shown && target && target.has(currentFocus())) {
      centreNow(currentFocus());
    }
  });
  el('follow').addEventListener('click', () => {
    following = true;
    relayout();
  });

  // ---- resizing the panes ------------------------------------------------------

  // Sizes are kept as percentages of the page, so they still fit when the
  // panel is resized, and in the webview's own state, so they survive the
  // panel being hidden and shown again.
  const main = document.querySelector('main');
  /// How small a pane may be dragged, in percent of the page.
  const MIN_PERCENT = 15;

  function applySizes(sizes) {
    for (const [key, prop] of [['left', '--left'], ['top', '--top']]) {
      if (sizes[key]) {
        main.style.setProperty(prop, sizes[key] + '%');
      } else {
        main.style.removeProperty(prop);
      }
    }
  }

  function sizes() {
    return (vscode.getState() || {}).sizes || {};
  }

  function saveSizes(s) {
    vscode.setState(Object.assign({}, vscode.getState() || {}, { sizes: s }));
    applySizes(s);
  }

  function splitter(id, key, horizontal) {
    const bar = el(id);
    bar.addEventListener('pointerdown', (down) => {
      down.preventDefault();
      bar.setPointerCapture(down.pointerId);
      bar.classList.add('dragging');
      const box = main.getBoundingClientRect();
      const move = (e) => {
        const at = horizontal ? (e.clientY - box.top) / box.height : (e.clientX - box.left) / box.width;
        const percent = Math.min(100 - MIN_PERCENT, Math.max(MIN_PERCENT, at * 100));
        const s = sizes();
        s[key] = Math.round(percent * 10) / 10;
        saveSizes(s);
      };
      const up = () => {
        bar.classList.remove('dragging');
        bar.removeEventListener('pointermove', move);
        bar.removeEventListener('pointerup', up);
        bar.removeEventListener('pointercancel', up);
      };
      bar.addEventListener('pointermove', move);
      bar.addEventListener('pointerup', up);
      bar.addEventListener('pointercancel', up);
    });
    // Back to where it started.
    bar.addEventListener('dblclick', () => {
      const s = sizes();
      delete s[key];
      saveSizes(s);
    });
  }

  splitter('split-x', 'left', false);
  splitter('split-y', 'top', true);
  applySizes(sizes());

  // ---- from the host ----------------------------------------------------------

  function drawState() {
    byNumber.clear();
    for (const o of state.objects) {
      byNumber.set(o.number, o);
    }
    el('score').textContent = 'Score ' + (state.score / 10).toFixed(1) + '%';
    el('here').textContent = 'You are at ' + state.playerAt + ': ' + roomName(state.playerAt);
    fillLogWho();
    drawObjects();
    drawCharacters();
    drawTimers();
    relayout();
  }

  window.addEventListener('message', (event) => {
    const m = event.data;
    if (m.type === 'layout') {
      setBase(m.cells);
      flagInfo = m.flags;
      el('flags-head').title = flagInfo.map((f) => f[1] + ' ' + f[2]).join('\n');
      if (state) {
        relayout();
      }
    } else if (m.type === 'state') {
      state = m.state;
      drawState();
    } else if (m.type === 'log') {
      addLogLines(m.lines, m.replace);
    } else if (m.type === 'logDropped') {
      const div = document.createElement('div');
      div.className = 'dropped';
      div.textContent = '(' + m.count + ' characters lost: the game printed faster than they could be sent)';
      logEl.appendChild(div);
    } else if (m.type === 'logStatus') {
      el('log-status').textContent = m.text;
    } else if (m.type === 'status') {
      el('status').textContent = m.text;
    }
  });

  vscode.postMessage({ type: 'ready' });
})();
