import QtQuick
import QtTest
import "../state/sources.js" as Sources
import "../state/http.js" as Http

TestCase {
    name: "Sources"
    function test_retryAfterHeader() {
        compare(Http.retryAfter("120"), "120")
        compare(Http.retryDisplay("120"), "120 s")
        compare(Http.retryAfter("Wed, 21 Oct 2015 07:28:00 GMT"), "Wed, 21 Oct 2015 07:28:00 GMT")
        compare(Http.retryAfter("<b>unsafe</b>"), "")
        compare(Http.retryAfter("-1"), "")
        compare(Http.retryAfter(null), "")
    }
    function test_migrateAndRepeat() {
        const old = JSON.stringify([
            { type: "web", name: "Search", template: "https://example.com/?q=%s", on: true },
            { type: "stremio", name: "Addon", url: "https://example.com/manifest.json", on: false }
        ])
        const first = Sources.migrate(old)
        compare(first.sources.length, 2)
        compare(first.invalid, 0)
        const second = Sources.migrate(first)
        compare(JSON.stringify(second), JSON.stringify(first))
    }
    function test_invalidDoesNotBreakOthers() {
        const result = Sources.migrate([{type:"web", name:"A", template:"https://example.com/?q=%s"},
                                        {type:"web", name:"B", template:"javascript:%s"}, null])
        compare(result.sources.length, 1)
        compare(result.invalid, 2)
        const corrupt = Sources.migrate("bad json")
        compare(corrupt.invalid, 1)
        compare(corrupt.recognized, false)
        compare(Sources.migrate({schemaVersion: 9, sources: []}).recognized, false)
    }
    function test_preferencesSurviveMigration() {
        const source = {type: "stremio", name: "Original", alias: "My source", url: "https://example.com/manifest.json", on: true, streamsEnabled: false, subtitlesEnabled: true}
        const saved = Sources.migrate(JSON.stringify({schemaVersion: 1, sources: [source]}))
        compare(saved.sources[0].name, "Original")
        compare(saved.sources[0].alias, "My source")
        compare(saved.sources[0].streamsEnabled, false)
        compare(saved.sources[0].subtitlesEnabled, true)
        compare(Sources.migrate(saved).sources[0].alias, "My source")
    }
    function test_reviewedManifestPreservesPreferencesAndDisablesNewCapability() {
        const old = { type: "stremio", name: "Old", alias: "Mine", url: "https://example.com/manifest.json", on: true, hasStreams: true, hasSubtitles: false, streamsEnabled: false }
        const info = { name: "New", hasStreams: true, hasSubtitles: true, types: [], prefixes: [], streamTypes: [], streamPrefixes: [], subtitleTypes: [], subtitlePrefixes: [] }
        const updated = Sources.applyManifest(old, info, old.url, 123, "host")
        compare(updated.name, "New")
        compare(updated.alias, "Mine")
        compare(updated.streamsEnabled, false)
        compare(updated.subtitlesEnabled, false)
        compare(updated.checkedAt, 123)
        compare(old.name, "Old")
        compare(Sources.migrate({schemaVersion: 1, sources: [updated]}).sources[0].checkedAt, 123)
    }
    function test_url() {
        compare(Sources.webUrl("https://example.com/search?q=%s", "a&b $1"), "https://example.com/search?q=a%26b%20%241")
        compare(Sources.webUrl("http://example.com/%s", "a b"), "http://example.com/a%20b")
        compare(Sources.webUrl("https://%s.example.com/", "evil"), "")
        compare(Sources.webUrl("https://example.com/", "x"), "")
        compare(Sources.webUrl("https://example.com/%s/%s", "x"), "")
    }
}
