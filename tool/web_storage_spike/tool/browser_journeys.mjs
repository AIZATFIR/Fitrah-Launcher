// Real page reload and two-tab storage checks, using Node's built-in CDP client.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');
const profile = await mkdtemp(resolve(tmpdir(), 'focus-clock-storage-'));
const mime = { '.html': 'text/html', '.js': 'text/javascript', '.wasm': 'application/wasm' };
const isolation = process.env.STORAGE_ISOLATION === '1';
const server = createServer(async (req, res) => {
  const file = resolve(root, '.' + new URL(req.url, 'http://localhost').pathname);
  if (!file.startsWith(root + sep)) return res.writeHead(403).end();
  try {
    const body = await readFile(file);
    res.writeHead(200, {
      'Content-Type': mime[extname(file)] ?? 'application/octet-stream',
      ...(isolation ? { 'Cross-Origin-Opener-Policy': 'same-origin', 'Cross-Origin-Embedder-Policy': 'require-corp' } : {}),
    });
    res.end(body);
  } catch {
    res.writeHead(404).end();
  }
});
await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const base = `http://127.0.0.1:${server.address().port}`;
const chrome = spawn(process.env.CHROME_EXECUTABLE ?? '/usr/bin/chromium', [
  '--headless=new', '--disable-gpu', '--no-first-run', '--no-default-browser-check',
  '--host-resolver-rules=MAP * ~NOTFOUND, EXCLUDE localhost, EXCLUDE 127.0.0.1',
  '--remote-debugging-port=0', `--user-data-dir=${profile}`, 'about:blank',
], { stdio: ['ignore', 'ignore', 'pipe'] });
let socket;
const pending = new Map();
const diagnostics = [];
let sequence = 0;
const delay = ms => new Promise(resolve => setTimeout(resolve, ms));
try {
  const endpoint = await new Promise((resolve, reject) => {
    const timeout = setTimeout(() => reject(Error('Chromium startup timed out')), 20000);
    let output = '';
    chrome.stderr.on('data', chunk => {
      output += chunk;
      const match = output.match(/DevTools listening on (ws:\/\/[^\s]+)/);
      if (match) { clearTimeout(timeout); resolve(match[1]); }
    });
    chrome.once('error', error => { clearTimeout(timeout); reject(error); });
    chrome.once('exit', code => { clearTimeout(timeout); reject(Error(`Chromium exited: ${code}`)); });
  });
  socket = new WebSocket(endpoint);
  await new Promise((resolve, reject) => {
    socket.addEventListener('open', resolve, { once: true });
    socket.addEventListener('error', reject, { once: true });
  });
  socket.addEventListener('message', event => {
    const message = JSON.parse(event.data);
    if (['Runtime.exceptionThrown', 'Network.loadingFailed', 'Log.entryAdded'].includes(message.method)) {
      diagnostics.push(message);
      if (diagnostics.length > 15) diagnostics.shift();
    }
    const request = pending.get(message.id);
    if (!request) return;
    pending.delete(message.id);
    clearTimeout(request.timeout);
    message.error ? request.reject(Error(JSON.stringify(message.error))) : request.resolve(message.result);
  });
  const send = (method, params = {}, sessionId) => new Promise((resolve, reject) => {
    const id = ++sequence;
    const timeout = setTimeout(() => { pending.delete(id); reject(Error(`${method} timed out`)); }, 15000);
    pending.set(id, { resolve, reject, timeout });
    socket.send(JSON.stringify({ id, method, params, ...(sessionId ? { sessionId } : {}) }));
  });
  async function evaluate(session, expression) {
    const response = await send('Runtime.evaluate', { expression, awaitPromise: true, returnByValue: true }, session);
    if (response.exceptionDetails) throw Error(JSON.stringify(response.exceptionDetails));
    return response.result.value;
  }
  async function ready(session) {
    const deadline = Date.now() + 20000;
    while (Date.now() < deadline) {
      try {
        if (await evaluate(session, 'typeof spikeCommand === "function"')) return;
        const text = await evaluate(session, 'document.body?.textContent ?? ""');
        if (text.startsWith('Storage probe failed:')) throw Error(text);
      } catch (error) {
        if (!/context.*destroyed|Cannot find.*context|navigated/i.test(String(error))) throw error;
      }
      await delay(100);
    }
    const text = await evaluate(session, 'document.body?.textContent?.slice(0, 300)');
    throw Error(`Storage probe did not become ready: ${text}; diagnostics=${JSON.stringify(diagnostics.slice(-5))}`);
  }
  async function reload(session) {
    const before = (await send('Page.getFrameTree', {}, session)).frameTree.frame.loaderId;
    await send('Page.reload', {}, session);
    const deadline = Date.now() + 20000;
    while ((await send('Page.getFrameTree', {}, session)).frameTree.frame.loaderId === before) {
      if (Date.now() >= deadline) throw Error('Page did not navigate on reload');
      await delay(100);
    }
    await ready(session);
  }
  const command = async (session, action) => JSON.parse(await evaluate(session, `spikeCommand(${JSON.stringify(action)})`));
  const db = `focus_clock_spike_journey_${Date.now()}`;
  async function tab() {
    const { targetId } = await send('Target.createTarget', { url: `${base}/web/probe.html?db=${db}` });
    const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
    await send('Runtime.enable', {}, sessionId);
    await send('Log.enable', {}, sessionId);
    await send('Network.enable', {}, sessionId);
    await ready(sessionId);
    return sessionId;
  }
  const a = await tab();
  assert.equal((await command(a, 'seed')).goal, 'Baca 20 halaman — tujuan 🌱');
  assert.equal((await command(a, 'start-initial')).timer.actualSeconds, 67);
  await reload(a);
  const afterReload = await command(a, 'read');
  assert.equal(afterReload.goal, 'Baca 20 halaman — tujuan 🌱');
  assert.equal(afterReload.timer.status, 'running');
  assert.equal(afterReload.timer.actualSeconds, 67);
  assert.equal(afterReload.timer.localDate, '2026-11-06');
  const b = await tab();
  assert.deepEqual(await command(b, 'read'), afterReload);
  assert.match((await command(b, 'rollback')).error, /Injected completion failure/);
  assert.deepEqual(await command(a, 'read'), afterReload);
  await command(b, 'complete');
  assert.equal((await command(a, 'read')).entries, 1);
  const race = await Promise.all([command(a, 'start-a'), command(b, 'start-b')]);
  assert.equal(race.filter(result => result.error).length, 1);
  assert.match(race.find(result => result.error).error, /UNIQUE constraint failed: sessions.id/);
  const afterRace = await command(a, 'read');
  assert.equal(afterRace.activities, 2);
  assert.equal(afterRace.sessions, 1);
  const completions = await Promise.all([command(a, 'complete'), command(b, 'complete')]);
  assert.ok(completions.every(result => !result.error));
  await reload(b);
  const final = await command(b, 'read');
  assert.equal(final.completed, 2);
  assert.equal(final.entries, 2);
  assert.equal(final.sessions, 0);
  assert.deepEqual(final.seconds, [67, 67]);
  console.log(JSON.stringify({ passed: ['page reload preserves running timer and goal', 'second tab reads same data', 'rollback visible across tabs', 'two-tab start has one winner and no orphan', 'two-tab completion is idempotent after reload'], mode: final.mode, isolation, browser: await send('Browser.getVersion') }, null, 2));
} finally {
  for (const request of pending.values()) clearTimeout(request.timeout);
  socket?.close();
  chrome.kill('SIGTERM');
  await new Promise(resolve => { if (chrome.exitCode !== null) resolve(); else chrome.once('exit', resolve); });
  await new Promise(resolve => server.close(resolve));
  await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
}
