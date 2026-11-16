// A new OpenSubtitles call replaces the one in flight and tells its caller, so nothing waits forever.
// Run with: node components/media-corner/tests/test_subtitle_calls.js
const assert = require('node:assert/strict')
const fs = require('node:fs')
const vm = require('node:vm')
const path = require('node:path')
const source = fs.readFileSync(path.join(__dirname, '../state/CornerSubtitles.qml'), 'utf8')

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
    return `root.${name} = function(${match[1].replace(/: (?:string|var|bool|int)/g, '')}) {${source.slice(start, end - 1)}}`
}

const sent = []
class FakeRequest {
    static DONE = 4
    constructor() { this.aborted = false; sent.push(this) }
    open() {}
    setRequestHeader() {}
    send() {}
    abort() { this.aborted = true }
}
const root = { request: null, callback: null, token: '', baseUrl: 'https://api.opensubtitles.com/api/v1/' }
const context = { root, timeout: { stop() {}, restart() {} }, XMLHttpRequest: FakeRequest,
    CornerState: { open: true, options: { subtitleApiKey: 'fixture' } }, Subtitles: {}, Http: {}, JSON }
vm.createContext(context)
for (const name of ['cancel', 'call']) vm.runInContext(qmlFunction(name), context)

const answers = []
root.call('GET', 'subtitles', '', (data, error) => answers.push(['search', error]))
root.call('POST', 'login', '{}', (data, error) => answers.push(['login', error]))
assert.equal(sent[0].aborted, true, 'the replaced request is aborted')
assert.deepEqual(answers, [['search', 'cancelled']], 'the replaced caller is told once')
root.cancel()
assert.deepEqual(answers, [['search', 'cancelled']], 'an explicit cancel tells nobody: its caller asked for it')
console.log('Subtitle call fixtures passed')
