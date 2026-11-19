// Real page reload and two-tab storage checks, using Node's built-in CDP client.
import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { createServer } from 'node:http';
import { readFile, mkdtemp, rm } from 'node:fs/promises';
import { tmpdir } from 'node:os';
import { dirname, extname, resolve, sep } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(process.argv[2]);
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
        if (await evaluate(session, 'typeof productionCommand === "function"')) return;
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
  const command = async (session, action) => JSON.parse(await evaluate(session, `productionCommand(${JSON.stringify(action)})`));
  const db = `focus_clock_production_test_${Date.now()}`;
  async function tab() {
    const { targetId } = await send('Target.createTarget', { url: `${base}/index.html?db=${db}` });
    const { sessionId } = await send('Target.attachToTarget', { targetId, flatten: true });
    await send('Runtime.enable', {}, sessionId);
    await send('Log.enable', {}, sessionId);
    await send('Network.enable', {}, sessionId);
    await ready(sessionId);
    return sessionId;
  }
  const passed = [];
  async function ok(session, action) {
    const result=await command(session,action);
    assert.equal(result.error,undefined,JSON.stringify(result));
    return result;
  }
  const a=await tab();
  const seeded=await ok(a,'seed');
  assert.equal(seeded.credentials,'SYNTHETIC-NON-SECRET');
  assert.equal(seeded.timer.data.status,1);
  assert.equal(seeded.timer.data.sourceKindIndex,999);
  await reload(a);
  assert.deepEqual(await ok(a,'read'),seeded);
  passed.push('all eight live models, raw credentials/session and goal survive page reload');
  const b=await tab();
  assert.deepEqual(await ok(b,'read'),seeded);
  await ok(a,'recurrence');
  await ok(a,'rollback');
  await ok(a,'unsafe-id');
  await ok(a,'nested');
  passed.push('recurrence/exclusions, repository task/settings writes, rollback watcher and ID allocation, unsafe IDs and nested transaction guard');
  await ok(a,'prepare'); await ok(b,'prepare');
  const starts=await Promise.all([command(a,'start'),command(b,'start')]);
  assert.equal(starts.filter(x=>x.error).length,1);
  await ok(a,'observe'); await ok(b,'observe');
  const completions=await Promise.all([ok(a,'complete'),ok(b,'complete')]);
  const completed=await ok(a,'read');
  assert.deepEqual(completed.entrySeconds,[91,67]);
  assert.equal(completed.counts['Sesi timer'],0);
  // Both clients must be able to begin again after an idempotent completion.
  await ok(b,'start'); await ok(b,'cancel');
  passed.push('two-tab habit start has one winner, completion contributes exactly 67 seconds once, losing client can start again');
  const activityStarts=await Promise.all([command(a,'start-activity'),command(b,'start-activity')]);
  assert.equal(activityStarts.filter(x=>x.error).length,1);
  await ok(a,'observe'); await ok(b,'observe');
  const activityCount=(await ok(a,'read')).counts.Jadwal;
  assert.equal(activityCount,2);
  await Promise.all([ok(a,'complete-activity'),ok(b,'complete-activity')]);
  assert.deepEqual((await ok(a,'read')).activitySeconds,[0,67]);
  passed.push('two-tab Activity start leaves no orphan; atomic completion is idempotent');
  await ok(a,'preference-failure');
  await ok(a,'restore');
  await reload(b);
  const recovery=await ok(b,'recovery');
  assert.ok(recovery.bytes.length>100);
  const recoveryText=new TextDecoder().decode(Uint8Array.from(recovery.bytes));
  // Keep aligned with FocusClockBackupCodec.currentFormatVersion.
  assert.equal(JSON.parse(recoveryText).formatVersion,5);
  assert.ok(!recoveryText.includes('SYNTHETIC-NON-SECRET'));
  passed.push('portable restore and preference failure compensate; durable recovery export bytes survive restart without credentials');
  console.log(JSON.stringify({passed,mode:completed.mode,isolation,browser:await send('Browser.getVersion')},null,2));

} finally {
  for (const request of pending.values()) clearTimeout(request.timeout);
  socket?.close();
  chrome.kill('SIGTERM');
  await new Promise(resolve => { if (chrome.exitCode !== null) resolve(); else chrome.once('exit', resolve); });
  await new Promise(resolve => server.close(resolve));
  await rm(profile, { recursive: true, force: true, maxRetries: 3, retryDelay: 100 });
}
