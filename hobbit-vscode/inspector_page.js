'use strict';
// The Hobbit Inspector's page: draws what the extension host sends it -- the
// decoded state, the map's layout and the log -- and asks for nothing but a
// cleared log. All the reading of the game happens in the host.

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

  let cells = {};
  let flagInfo = [];
  let state = null;
  /// Where the map was last scrolled to follow the player, so it moves only
  /// when the player does and is otherwise left where the user put it.
  let followed = -1;
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

  function drawMap() {
    const map = el('map');
    map.textContent = '';
    const placed = state.rooms.filter((r) => cells[r.location]);
    if (!placed.length) {
      return;
    }
    const xs = placed.map((r) => cells[r.location][0]);
    const ys = placed.map((r) => cells[r.location][1]);
    const minX = Math.min(...xs);
    const minY = Math.min(...ys);
    const width = (Math.max(...xs) - minX + 1) * CELL_W + 8;
    const height = (Math.max(...ys) - minY + 1) * CELL_H + 8;
    const zoom = Number(el('zoom').value) / 100;
    map.setAttribute('width', String(width * zoom));
    map.setAttribute('height', String(height * zoom));
    map.setAttribute('viewBox', '0 0 ' + width + ' ' + height);
    // The layout's cells are the site map's: x east, y south, so north is up.
    const centre = (location) => {
      const [x, y] = cells[location];
      return [(x - minX) * CELL_W + 4 + CELL_W / 2, (y - minY) * CELL_H + 4 + CELL_H / 2];
    };

    // Exits first, under the rooms: one line per pair of places, dashed where
    // the way back is not the way there.
    const exits = svg('g', {}, map);
    const drawn = new Set();
    const leadsTo = new Map(state.rooms.map((r) => [r.location, new Set(r.exits.map((e) => e.to))]));
    for (const r of placed) {
      for (const e of r.exits) {
        if (!e.to || !cells[e.to] || e.to === r.location) {
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
        svg('line', {
          class: 'exit' + (back && back.has(r.location) ? '' : ' oneway'),
          x1, y1, x2, y2,
        }, exits);
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

    for (const r of placed) {
      const [cx, cy] = centre(r.location);
      const g = svg('g', {
        class: 'room' + (r.lit ? '' : ' dark') + (r.visited ? '' : ' unvisited')
          + (r.location === state.playerAt ? ' you' : ''),
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
        + '\nExits: ' + (r.exits.map((e) => e.direction + ' ' + e.to).join(', ') || 'none');
      const lines = wrapName(r.name);
      lines.forEach((text, i) => {
        const t = svg('text', { x: x + 4, y: y + 12 + i * 10 }, g);
        t.textContent = text;
      });
      const n = svg('text', { class: 'number', x: x + ROOM_W - 4, y: y + ROOM_H - 4, 'text-anchor': 'end' }, g);
      n.textContent = String(r.location);
      if (r.location === state.playerAt && followed !== r.location) {
        followed = r.location;
        const scroll = el('map-scroll');
        scroll.scrollLeft = cx * zoom - scroll.clientWidth / 2;
        scroll.scrollTop = cy * zoom - scroll.clientHeight / 2;
      }
      // A dot per character, along the bottom of the box.
      here.forEach((o, i) => {
        const dx = x + 7 + i * 11;
        const dy = y + ROOM_H - 7;
        svg('circle', { class: 'who', cx: dx, cy: dy, r: 5, fill: colourOf(o.number) }, g);
        const t = svg('text', { class: 'who', x: dx, y: dy + 2.5, 'text-anchor': 'middle' }, g);
        t.textContent = o.number === 0 ? '@' : o.name.split(' ').pop()[0].toUpperCase();
      });
    }
  }
  el('zoom').addEventListener('input', () => state && drawMap());

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
    drawMap();
  }

  window.addEventListener('message', (event) => {
    const m = event.data;
    if (m.type === 'layout') {
      cells = m.cells;
      flagInfo = m.flags;
      el('flags-head').title = flagInfo.map((f) => f[1] + ' ' + f[2]).join('\n');
      if (state) {
        drawMap();
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
