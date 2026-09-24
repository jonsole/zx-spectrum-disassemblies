'use strict';
// The Hobbit Inspector's page: draws what the extension host sends it -- the
// decoded state and the log -- and asks for nothing but a cleared log. All the
// reading of the game happens in the host; the map's layout is map_flow.js.

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
      div.className = 'line' + (line.actor === 0 ? ' you' : '') + ' ' + (line.kind || 'shown');
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
        ['num', hex2(o.placed)],
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

  // The map is flowed out from one place (map_flow.js): the player's, or one
  // clicked on. That place's exits always point their own way, and when it
  // changes the map flows from the old layout to the new rather than jumping.
  let following = true;
  let focus = 0;
  /// The layout being shown, as it moves: location -> [x, y] in cells, which
  /// are fractions while it flows.
  let shown = null;
  let target = null;
  let flowFrom = null;
  let flowStart = 0;
  let animating = false;
  /// How far the canvas reaches from the focus, in cells, each way.
  let reach = [1, 1];
  const FLOW_MS = 450;

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

  /// Lays the map out around the current focus, and flows to it if it moved.
  function relayout() {
    const f = currentFocus();
    updateFollowUi();
    if (!f) {
      return;
    }
    const next = MapFlow.flow(state.rooms, f);
    if (sameLayout(target, next)) {
      if (!animating) {
        drawMap();
      }
      return;
    }
    flowFrom = shown ? new Map(shown) : null;
    target = next;
    // The canvas is sized for both layouts at once, so it stays still while
    // the places move across it, with the focus at its centre.
    let rx = 1;
    let ry = 1;
    for (const layout of [target, flowFrom]) {
      for (const [x, y] of layout ? layout.values() : []) {
        rx = Math.max(rx, Math.ceil(Math.abs(x)));
        ry = Math.max(ry, Math.ceil(Math.abs(y)));
      }
    }
    reach = [rx, ry];
    if (!flowFrom) {
      shown = new Map(target);
      drawMap();
      centreView();
      return;
    }
    flowStart = performance.now();
    centreView();
    if (!animating) {
      animating = true;
      requestAnimationFrame(flowStep);
    }
  }

  function flowStep(now) {
    const t = Math.min(1, (now - flowStart) / FLOW_MS);
    const ease = t < 0.5 ? 2 * t * t : 1 - Math.pow(-2 * t + 2, 2) / 2;
    shown = new Map();
    for (const [loc, [x1, y1]] of target) {
      const from = flowFrom.get(loc) || [x1, y1];
      shown.set(loc, [from[0] + (x1 - from[0]) * ease, from[1] + (y1 - from[1]) * ease]);
    }
    drawMap();
    if (t < 1) {
      requestAnimationFrame(flowStep);
    } else {
      animating = false;
      shown = new Map(target);
    }
  }

  function zoom() {
    return Number(el('zoom').value) / 100;
  }

  function centreView() {
    requestAnimationFrame(() => {
      const scroll = el('map-scroll');
      const z = zoom();
      scroll.scrollLeft = ((reach[0] + 0.5) * CELL_W + 4) * z - scroll.clientWidth / 2;
      scroll.scrollTop = ((reach[1] + 0.5) * CELL_H + 4) * z - scroll.clientHeight / 2;
    });
  }

  function drawMap() {
    const map = el('map');
    map.textContent = '';
    if (!shown) {
      return;
    }
    const width = (2 * reach[0] + 1) * CELL_W + 8;
    const height = (2 * reach[1] + 1) * CELL_H + 8;
    const z = zoom();
    map.setAttribute('width', String(width * z));
    map.setAttribute('height', String(height * z));
    map.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    // x east, y south: north is up, and the focus is in the middle.
    const centre = (location) => {
      const [x, y] = shown.get(location);
      return [(x + reach[0]) * CELL_W + 4 + CELL_W / 2, (y + reach[1]) * CELL_H + 4 + CELL_H / 2];
    };
    const f = currentFocus();

    // Exits first, under the rooms: one line per pair of places, dashed where
    // the way back is not the way there. The focus's own are drawn last, on
    // top, with their directions.
    const exits = svg('g', {}, map);
    const drawn = new Set();
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
        }
      }
      for (const [to, directions] of ways) {
        const [x2, y2] = centre(to);
        const back = leadsTo.get(to);
        svg('line', { class: 'exit focus' + (back && back.has(f) ? '' : ' oneway'), x1, y1, x2, y2 }, exits);
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
        + '\nExits: ' + (r.exits.map((e) => e.direction + ' ' + e.to).join(', ') || 'none')
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

    // The focus's directions, over everything.
    for (const [lx, ly, text] of labels) {
      const t = svg('text', { class: 'exit-label', x: lx, y: ly + 3, 'text-anchor': 'middle' }, map);
      t.textContent = text;
    }
  }
  el('zoom').addEventListener('input', () => {
    if (state) {
      drawMap();
      centreView();
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
    drawObjects();
    relayout();
  }

  window.addEventListener('message', (event) => {
    const m = event.data;
    if (m.type === 'flags') {
      flagInfo = m.flags;
      el('flags-head').title = flagInfo.map((f) => f[1] + ' ' + f[2]).join('\n');
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
