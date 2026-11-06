#!/usr/bin/env bun
// tests/test_relay.ts — the relay bridge against two fake fakechat servers (no Claude sessions needed).
// A fake server does what fakechat does: POST /upload → "delivered to the session" (recorded here); websocket /ws → we push
// {type:'msg', from:'assistant', ...} to the bridge as if the session had called fakechat's reply tool.
// Run from the repo root: bun tests/test_relay.ts
import { mkdtempSync, rmSync, writeFileSync, readdirSync } from 'fs'
import { tmpdir } from 'os'
import { join } from 'path'

const T = mkdtempSync(join(tmpdir(), 'anna-relay-test-'))
const [BRAIN, BOT] = [18000 + Math.floor(Math.random() * 1000), 19000 + Math.floor(Math.random() * 1000)]
type Fake = { uploads: { id: string; text: string }[]; push: (m: object) => void }

function fake(port: number): Fake {
  const sockets = new Set<any>(); const f: Fake = { uploads: [], push: m => sockets.forEach(s => s.send(JSON.stringify(m))) }
  Bun.serve({
    port, hostname: '127.0.0.1',
    async fetch(req, server) {
      const u = new URL(req.url)
      if (u.pathname === '/ws') return server.upgrade(req) ? undefined : new Response('no', { status: 400 })
      if (u.pathname === '/upload') { const fd = await req.formData(); f.uploads.push({ id: String(fd.get('id')), text: String(fd.get('text')) }); return new Response(null, { status: 204 }) }
      return new Response('fake fakechat')
    },
    websocket: { open: s => { sockets.add(s) }, close: s => { sockets.delete(s) }, message: () => {} },
  })
  return f
}

const brain = fake(BRAIN), bot = fake(BOT)
writeFileSync(join(T, 'anna.toml'), `[anna]\nuser = "Sam"\ntimezone = "UTC"\n[relay]\nalarm_min = 30\n`)
const bridge = Bun.spawn(['bun', 'bin/anna-relay', 'bridge'], {
  env: { ...process.env, ANNA_CONFIG: join(T, 'anna.toml'), ANNA_RELAY_DIR: join(T, 'q'), ANNA_RELAY_NOSTREAM: '1',
         RELAY_BRAIN_PORT: String(BRAIN), RELAY_BOT_PORT: String(BOT), RELAY_SETTLE_MS: '300', RELAY_TICK_MS: '100' },
  stdout: 'pipe', stderr: 'pipe',
})
const sleep = (ms: number) => new Promise(r => setTimeout(r, ms))
const until = async (cond: () => boolean, ms = 4000) => { const t = Date.now(); while (!cond() && Date.now() - t < ms) await sleep(50); return cond() }
const files = (d: string) => readdirSync(join(T, 'q', d)).filter(f => f.endsWith('.json'))
let fail = 0
const ok = (name: string, c: boolean) => { console.log(`${c ? 'ok  ' : 'FAIL'} ${name}`); if (!c) fail = 1 }

try {
  await sleep(1000)                                                    // bridge connects + settles

  bot.push({ type: 'msg', from: 'assistant', text: 'RELAY: how full is the disk? / I told her: on it' })
  ok('a RELAY: hand-off reaches the brain', await until(() => brain.uploads.length === 1))
  const req = brain.uploads[0]
  ok('the brain sees the words and the id to reply to', req?.text.includes('how full is the disk') && req.text.includes(`reply_to="${req.id}"`))

  brain.push({ type: 'msg', from: 'assistant', text: '[progress] checking now', replyTo: req.id })
  ok('progress goes to the bot as progress', await until(() => bot.uploads.some(u => u.text.startsWith(`[relay progress for ${req.id}]`))))
  brain.push({ type: 'msg', from: 'assistant', text: 'The disk is 42% full.', replyTo: req.id })
  ok('the result goes to the bot', await until(() => bot.uploads.some(u => u.text.startsWith(`[relay result for ${req.id}]`))))
  ok('the result names the user and keeps the facts', bot.uploads.some(u => u.text.includes('Tell Sam on Telegram') && u.text.includes('42% full')))
  ok('the item ends in done/', await until(() => files('done').length === 1))

  const before = brain.uploads.length
  bot.push({ type: 'msg', from: 'assistant', text: 'Thanks, told her.' })                          // no marker
  bot.push({ type: 'msg', from: 'assistant', text: 'RELAY: again', replyTo: `${req.id}-res1` })   // a reply, not a hand-off
  await sleep(600)
  ok('bot messages without RELAY: or with reply_to are dropped', brain.uploads.length === before && files('new').length === 0)

  writeFileSync(join(T, 'q', 'paused'), '')
  bot.push({ type: 'msg', from: 'assistant', text: 'RELAY: overnight job' })
  ok('paused: the hand-off waits in new/', await until(() => files('new').length === 1) && brain.uploads.length === before)
  ok('paused: the bot is told once', await until(() => bot.uploads.some(u => u.text.startsWith('[relay status for')), 13000))
  rmSync(join(T, 'q', 'paused'))
  ok('unpaused: it goes to the brain', await until(() => brain.uploads.length === before + 1))

  for (let i = 0; i < 7; i++) bot.push({ type: 'msg', from: 'assistant', text: `RELAY: flood ${i}` })
  await sleep(800)
  const flood = brain.uploads.filter(u => u.text.includes('flood')).length
  ok(`breaker: a flood is cut off (${flood} of 7 got through)`, flood <= 5)
} finally {
  bridge.kill(); rmSync(T, { recursive: true, force: true })
}
process.exit(fail)
