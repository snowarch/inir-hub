// Exercise the actual QML JavaScript functions with stubbed player and network objects.
// Run with: node components/media-corner/tests/test_playback_lifecycle.js
const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const source = fs.readFileSync(path.join(__dirname, '../state/CornerWatch.qml'), 'utf8')

function qmlFunction(name) {
    const match = new RegExp(`function ${name}\\(([^)]*)\\): void \\{`).exec(source)
    assert.ok(match, `Missing QML function ${name}`)
    let depth = 1, end = match.index + match[0].length
    const start = end
    while (depth && end < source.length) {
        if (source[end] === '{') depth++
        if (source[end] === '}') depth--
        end++
    }
    assert.equal(depth, 0, `Unclosed QML function ${name}`)
    return `root.${name} = function(${match[1].replace(/: (?:string|var|bool)/g, '')}) {${source.slice(start, end - 1)}}`
}
function exitHandler() {
    const process = source.indexOf('        id: mpv\n')
    const start = source.indexOf('        onExited: code => {', process)
    assert.ok(process >= 0 && start >= 0, 'Missing mpv exit handler')
    let end = source.indexOf('{', start) + 1, depth = 1
    const body = end
    while (depth && end < source.length) {
        if (source[end] === '{') depth++
        if (source[end] === '}') depth--
        end++
    }
    assert.equal(depth, 0)
    return `root.exited = code => {${source.slice(body, end - 1)}}`
}
function harness() {
    let callback = null, canceled = [], kept = 0, starts = []
    const root = { _ticket: 0, _watchCalls: [], _stopping: false, _next: null, phase: 'choosing', subtitleChoiceMade: true, progressLoaded: true, selectedSubtitle: null,
        _keep: () => { kept++ }, _start: (stream, resume) => starts.push({ stream, resume }), _ask: () => {} }
    const mpv = { running: false }
    const CornerState = { open: true, sheet: true, options: { subtitleApiKey: '' }, ask: (url, body, shape, done) => { callback = done }, cancelAsk: done => canceled.push(done) }
    const CornerSubtitles = { cancel() {}, download: (id, done) => { callback = done }, limitedMessage: retryAfter => 'limited' + retryAfter }
    const writes = []
    const controlSocket = { item: { write: data => writes.push(JSON.parse(data)), flush() {} } }
    const context = { root, mpv, mpvCheck: {}, controlSocket, CornerState, CornerSubtitles, CornerSources: { addons: [], subtitles: [] }, Streams: { mediaUrl: value => !!value }, Translation: { tr: value => value } }
    vm.createContext(context)
    for (const name of ['_cancelWatchCalls', '_watchAsk', 'begin', 'cancel', 'play', 'stop', 'selectTrack']) vm.runInContext(qmlFunction(name), context)
    vm.runInContext(exitHandler(), context)
    return { root, mpv, get callback() { return callback }, get canceled() { return canceled }, get kept() { return kept }, starts, writes }
}
const stream = { url: 'fixture-video' }
{
    const h = harness()
    h.root.selectedSubtitle = { fileId: 12 }
    h.root.play(stream, true)
    const late = h.callback
    assert.equal(h.root.phase, 'launching')
    h.root.stop()
    late('fixture-subtitle', '')
    assert.equal(h.root.phase, 'idle')
    assert.equal(h.starts.length, 0, 'late download must not start a player')
}
{
    const h = harness()
    h.mpv.running = true
    h.root.phase = 'playing'
    h.root.begin({ id: 'tt123', kind: 'movie' }, null)
    assert.equal(h.kept, 1)
    assert.equal(h.mpv.running, false)
    h.root.play(stream, false)
    assert.equal(h.root.phase, 'launching')
    assert.equal(h.root._next.stream, stream)
    h.root.cancel()
    assert.equal(h.root._next, null, 'cancel must discard queued playback')
    assert.equal(h.root.phase, 'idle')
    h.root.exited(0)
    assert.equal(h.starts.length, 0, 'late player exit must not start canceled playback')
}
{
    const h = harness()
    h.mpv.running = true
    h.root.phase = 'playing'
    h.root.begin({ id: 'tt123', kind: 'movie' }, null)
    h.root.play(stream, true)
    h.root.exited(0)
    assert.equal(h.starts.length, 1)
    assert.equal(h.starts[0].stream, stream)
    assert.equal(h.starts[0].resume, true)
}
{
    const h = harness()
    h.root._watchAsk('fixture-request', x => x, () => {})
    const outstanding = h.callback
    h.root.cancel()
    assert.equal(h.canceled.length, 1)
    assert.equal(h.canceled[0], outstanding)
    assert.equal(h.root._watchCalls.length, 0)
}
{
    const h = harness()
    h.root.progressLoaded = false
    h.root.play(stream, false)
    assert.equal(h.starts.length, 0, 'unloaded progress must block playback')
    h.root.progressLoaded = true
    h.root.selectedSubtitle = { fileId: 12 }
    h.root.play(stream, true)
    h.callback('', 'busy')
    assert.equal(h.root.phase, 'choosing')
    assert.equal(h.root.retryPlayback.stream, stream)
    assert.equal(h.root.retryPlayback.resume, true)
}
{
    const h = harness()
    h.root.phase = 'playing'
    h.root.controlLinked = true
    h.root.playbackTracks = [{type: 'audio', id: 2}, {type: 'sub', id: 3}]
    h.root.selectTrack('audio', 2)
    h.root.selectTrack('sub', 'no')
    h.root.selectTrack('audio', 99)
    h.root.selectTrack('video', 3)
    assert.deepEqual(h.writes.map(item => item.command), [['set_property', 'aid', 2], ['set_property', 'sid', 'no']])
}
{
    const h = harness()
    h.root.phase = 'launching'
    h.root.exited(1)
    assert.equal(h.root.error, 'mpv could not start. Check its configuration')
    assert.equal(h.root.phase, 'choosing')
}
{
    const h = harness()
    h.root.phase = 'playing'
    h.root.exited(2)
    assert.equal(h.kept, 1)
    assert.equal(h.root.error, 'mpv stopped with an error. Try another stream')
    assert.equal(h.root.phase, 'choosing')
}
console.log('Playback lifecycle fixtures passed')
