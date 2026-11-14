import QtQuick
import QtTest
import "../state/sources.js" as Sources

TestCase {
    name: "Sources"
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
    function test_url() {
        compare(Sources.webUrl("https://example.com/search?q=%s", "a&b $1"), "https://example.com/search?q=a%26b%20%241")
        compare(Sources.webUrl("http://example.com/%s", "a b"), "http://example.com/a%20b")
        compare(Sources.webUrl("https://%s.example.com/", "evil"), "")
        compare(Sources.webUrl("https://example.com/", "x"), "")
        compare(Sources.webUrl("https://example.com/%s/%s", "x"), "")
    }
}
