'use strict';
// The Hobbit Inspector: what The Hobbit is doing while it runs in the
// emulator -- its locations on a map, with who is where; every object, its
// place, holder, sizes and flags; and a log of everything the game says, for
// every character, seen or not. After Wilderland (github.com/efa/Wilderland),
// which does the same with its own emulator.
//
// It reads the game through the ZX Spectrum debug session: memory with DAP's
// readMemory, polled while the panel is open, and the text with a logpoint on
// PRINT_CHAR, whose reports arrive as zxLog events. What the bytes mean is in
// hobbit_model.js, which does not need VS Code.

const vscode = require('vscode');
const fs = require('fs');
const path = require('path');
const model = require('./hobbit_model');

/// The emulator extension's debug type.
const DEBUG_TYPE = 'zxspectrum';
/// How often the game's state is read while the panel is open. The reads are
/// about 10K, and a run services them at its yields without stopping.
const POLL_MS = 400;
/// The group this extension's logpoint is set under.
const LOG_GROUP = 'hobbit';

let panel = null;
let pageReady = false;
let queued = [];
let session = null;
let pollTimer = null;
let polling = false;
let lastState = '';
let isTheHobbit = false;
let logpointSet = false;
const log = new model.LogAssembler(2000);

function activate(context) {
  context.subscriptions.push(
    vscode.commands.registerCommand('hobbit.inspector.open', () => openPanel(context)),
    vscode.debug.onDidStartDebugSession((s) => {
      if (panel && s.type === DEBUG_TYPE && !session) {
        attach(s);
      }
    }),
    vscode.debug.onDidChangeActiveDebugSession((s) => {
      if (panel && s && s.type === DEBUG_TYPE && s !== session) {
        attach(s);
      }
    }),
    vscode.debug.onDidTerminateDebugSession((s) => {
      if (s === session) {
        session = null;
        logpointSet = false;
        status('The debug session has ended. Start one with The Hobbit loaded.');
      }
    }),
    vscode.debug.onDidReceiveDebugSessionCustomEvent((e) => {
      if (e.session !== session || e.event !== 'zxLog' || !e.body || e.body.group !== LOG_GROUP) {
        return;
      }
      const lines = log.push((e.body.lines || []).map((l) => l.text));
      if (lines.length) {
        post({ type: 'log', lines });
      }
      if (e.body.dropped) {
        post({ type: 'logDropped', count: e.body.dropped });
      }
    })
  );
}

function deactivate() {
  stopPolling();
}

function openPanel(context) {
  if (panel) {
    panel.reveal();
    return;
  }
  panel = vscode.window.createWebviewPanel('hobbit.inspector', 'The Hobbit', vscode.ViewColumn.Beside, {
    enableScripts: true,
    retainContextWhenHidden: true,
    localResourceRoots: [vscode.Uri.file(context.extensionPath)],
  });
  pageReady = false;
  queued = [];
  panel.webview.html = pageHtml(panel.webview, context.extensionPath);
  panel.webview.onDidReceiveMessage((message) => {
    if (message.type === 'ready') {
      pageReady = true;
      panel.webview.postMessage({ type: 'flags', flags: model.FLAGS });
      for (const m of queued) {
        panel.webview.postMessage(m);
      }
      queued = [];
      if (lastState) {
        panel.webview.postMessage({ type: 'state', state: JSON.parse(lastState) });
      }
      panel.webview.postMessage({ type: 'log', lines: log.lines, replace: true });
    } else if (message.type === 'clearLog') {
      log.lines.length = 0;
    }
  });
  panel.onDidDispose(() => {
    stopPolling();
    clearLogpoint();
    panel = null;
  });
  const active = vscode.debug.activeDebugSession;
  if (active && active.type === DEBUG_TYPE) {
    attach(active);
  } else {
    status('No ZX Spectrum debug session. Start one with The Hobbit loaded.');
  }
  pollTimer = setInterval(poll, POLL_MS);
}

function attach(s) {
  if (session && session !== s) {
    clearLogpoint();
  }
  session = s;
  logpointSet = false;
  isTheHobbit = false;
  lastState = '';
  status('Reading ' + s.name + '...');
  poll();
}

function stopPolling() {
  if (pollTimer) {
    clearInterval(pollTimer);
    pollTimer = null;
  }
}

async function read(s, range) {
  const body = await s.customRequest('readMemory', {
    memoryReference: range[0],
    offset: 0,
    count: range[1] - range[0],
  });
  return Buffer.from((body && body.data) || '', 'base64');
}

async function poll() {
  if (!panel || !session || polling) {
    return;
  }
  polling = true;
  const s = session;
  try {
    // The dictionary is read every time too: it is only 4K, and a different
    // program loaded under the same session would otherwise keep the old
    // one's words.
    const mem = new Uint8Array(0x10000);
    mem.set(await read(s, model.DICTIONARY_RANGE), model.DICTIONARY_RANGE[0]);
    mem.set(await read(s, model.STATE_RANGE), model.STATE_RANGE[0]);
    if (s !== session) {
      return;
    }
    const state = model.readState(mem);
    if (!state) {
      if (isTheHobbit || lastState === '') {
        status('The program in the emulator is not The Hobbit v1.2.');
      }
      isTheHobbit = false;
      lastState = 'none';
      clearLogpoint();
      return;
    }
    if (!isTheHobbit) {
      isTheHobbit = true;
      status('');
      await setLogpoint(s);
    }
    const json = JSON.stringify(state);
    if (json !== lastState) {
      lastState = json;
      post({ type: 'state', state });
    }
  } catch (e) {
    status('Could not read the emulator: ' + (e && e.message ? e.message : e));
  } finally {
    polling = false;
  }
}

/// The log's logpoints -- PRINT_CHAR, and where words start and wrap -- set
/// only once the game is known to be The Hobbit: anywhere else, those
/// addresses are someone else's code.
async function setLogpoint(s) {
  if (logpointSet) {
    return;
  }
  try {
    const body = await s.customRequest('setLogpoints', {
      group: LOG_GROUP,
      logpoints: model.LOGPOINTS,
    });
    const results = (body && body.logpoints) || [];
    const failed = results.find((r) => !r.verified);
    if (results.length !== model.LOGPOINTS.length || failed) {
      post({ type: 'logStatus', text: 'The log could not be set up: ' + ((failed && failed.message) || 'no reply') });
      return;
    }
    logpointSet = true;
    post({ type: 'logStatus', text: '' });
  } catch (e) {
    post({
      type: 'logStatus',
      text: 'This emulator has no logpoints, so there is no log. Restart it from a build that has them.',
    });
  }
}

function clearLogpoint() {
  if (!session || !logpointSet) {
    return;
  }
  logpointSet = false;
  session.customRequest('setLogpoints', { group: LOG_GROUP, logpoints: [] }).then(
    () => {},
    () => {}
  );
}

function status(text) {
  post({ type: 'status', text });
}

/// Messages posted before the page says it is ready would be lost, so they
/// wait for it.
function post(message) {
  if (!panel) {
    return;
  }
  if (!pageReady) {
    queued.push(message);
    return;
  }
  panel.webview.postMessage(message);
}

function pageHtml(webview, root) {
  const nonce = [...Array(24)].map(() => Math.floor(Math.random() * 36).toString(36)).join('');
  const script = webview.asWebviewUri(vscode.Uri.file(path.join(root, 'inspector_page.js')));
  const style = webview.asWebviewUri(vscode.Uri.file(path.join(root, 'inspector.css')));
  const flow = webview.asWebviewUri(vscode.Uri.file(path.join(root, 'map_flow.js')));
  return fs
    .readFileSync(path.join(root, 'inspector.html'), 'utf8')
    .replace(/\$\{csp\}/g, webview.cspSource)
    .replace(/\$\{nonce\}/g, nonce)
    .replace(/\$\{script\}/g, String(script))
    .replace(/\$\{style\}/g, String(style))
    .replace(/\$\{flow\}/g, String(flow));
}

module.exports = { activate, deactivate };
