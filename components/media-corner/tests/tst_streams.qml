import QtQuick
import QtTest
import "../state/streams.js" as Streams

// Run with: QT_QPA_PLATFORM=offscreen /usr/lib/qt6/bin/qmltestrunner -input components/media-corner/tests/tst_streams.qml
TestCase {
    name: "Streams"

    function test_baseOf() {
        compare(Streams.baseOf("https://a.example.com/x/manifest.json"), "https://a.example.com/x")
        compare(Streams.baseOf("stremio://a.example.com/manifest.json"), "https://a.example.com")
        compare(Streams.baseOf("http://a.example.com/manifest.json"), "")
        compare(Streams.baseOf("https://a.example.com/x"), "")
        compare(Streams.baseOf("https://a.example.com/manifest.json --script=x"), "")
    }
    function test_hostHidesTheToken() {
        compare(Streams.hostOf("https://user:pass@a.example.com/secret/manifest.json"), "a.example.com")
    }
    function test_manifest() {
        compare(Streams.manifestInfo({ resources: ["catalog"] }), null)
        const plain = Streams.manifestInfo({ name: "A", resources: ["stream"], types: ["movie"], idPrefixes: ["tt"] })
        compare(plain.prefixes, ["tt"])
        const inner = Streams.manifestInfo({ resources: [{ name: "stream", types: ["series"], idPrefixes: ["kitsu"] }] })
        compare(inner.types, ["series"])
        compare(inner.prefixes, ["kitsu"])
        const mixed = Streams.manifestInfo({ resources: [
            { name: "stream", types: ["series"], idPrefixes: ["kitsu"] },
            { name: "subtitles", types: ["movie"], idPrefixes: ["tt"] }
        ] })
        compare(Streams.pathFor(mixed, { kind: "movie", id: "tt123" }, null, ""), "")
        compare(Streams.pathFor(mixed, { kind: "movie", id: "tt123" }, null, "", "subtitles"), "movie/tt123")
        compare(Streams.pathFor(mixed, { kind: "anime", id: 5 }, { episode: 7 }, "9"), "series/kitsu:9:7")
        compare(Streams.pathFor(mixed, { kind: "anime", id: 5 }, { episode: 7 }, "9", "subtitles"), "")
    }
    function test_subtitles() {
        const info = Streams.manifestInfo({ resources: ["subtitles"] })
        verify(info.hasSubtitles)
        verify(!info.hasStreams)
        const result = Streams.subtitlesFrom({subtitles: [
            {lang:"eng", url:"https://example.com/a.srt", label:"English"},
            {lang:"en", url:"file:///etc/passwd"},
            {lang:"../", url:"https://example.com/a.srt"}
        ]})
        compare(result.length, 1)
        compare(result[0].name, "English")
    }
    function test_onlyHttpsPlays() {
        const found = Streams.streamsFrom({ streams: [
            { infoHash: "abc" },
            { externalUrl: "https://a.example.com/page" },
            { url: "http://a.example.com/v.mp4" },
            { url: "https://a.example.com/v x.mp4" },
            { url: "edl://a" },
            { url: "https://a.example.com/v.mp4", name: "1080p\nmore", behaviorHints: { proxyHeaders: { request: { Referer: "https://b.example.com/" } } } },
            { url: "https://a.example.com/w.mp4", behaviorHints: { proxyHeaders: { request: { Referer: "--script=x" } } } }
        ] })
        compare(found.length, 2)
        compare(found[0].name, "1080p")
        compare(found[0].referer, "https://b.example.com/")
        compare(found[1].name, "Stream")
        compare(found[1].referer, "")
        compare(Streams.streamsFrom(null).length, 0)
    }
    function test_paths() {
        const any = { types: [], prefixes: [] }
        compare(Streams.pathFor(any, { kind: "movie", id: "tt123" }, null, ""), "movie/tt123")
        compare(Streams.pathFor(any, { kind: "series", id: "tt123" }, { season: 2, episode: 3 }, ""), "series/tt123:2:3")
        compare(Streams.pathFor(any, { kind: "movie", id: "../x" }, null, ""), "")
        compare(Streams.pathFor(any, { kind: "anime", id: 5 }, { episode: 7 }, ""), "")
        compare(Streams.pathFor(any, { kind: "anime", id: 5 }, { episode: 7 }, "9"), "series/kitsu:9:7")
        compare(Streams.pathFor({ types: ["anime"], prefixes: ["kitsu"] }, { kind: "anime", id: 5 }, { episode: 7 }, "9"), "anime/kitsu:9:7")
        compare(Streams.pathFor({ types: ["movie"], prefixes: ["tt"] }, { kind: "anime", id: 5, film: true }, null, "9"), "")
        compare(Streams.pathFor({ types: ["series"], prefixes: ["tt"] }, { kind: "movie", id: "tt1" }, null, ""), "")
    }
    function test_web() {
        verify(Streams.validTemplate("https://a.example.com/s?q=%s"))
        verify(!Streams.validTemplate("https://a.example.com/s"))
        verify(!Streams.validTemplate("javascript:alert(%s)"))
        compare(Streams.webUrl("https://a.example.com/s?q=%s", "a&b $1"), "https://a.example.com/s?q=a%26b%20%241")
    }
    function test_status() {
        compare(Streams.statusFrom("@@POS  1.400000 no"), null)
        compare(Streams.statusFrom("Cannot seek in this stream."), null)
        compare(Streams.statusFrom("@@POS 0.200000 1.600000 no").duration, 1.6)
        compare(Streams.statusFrom("@@POS 0.200000 1.600000 no").window, false)
        compare(Streams.statusFrom("@@POS 12.5  yes").position, 12.5)
        compare(Streams.statusFrom("@@POS 12.5  yes").duration, 0)
        compare(Streams.statusFrom("@@POS 12.5  yes").window, true)
    }
    function test_keysAndClock() {
        compare(Streams.watchKey({ id: "tt1" }, null), "tt1")
        compare(Streams.watchKey({ id: "tt1" }, { season: 1, episode: 2 }), "tt1:1:2")
        compare(Streams.watchKey({ id: 5 }, { episode: 2 }), "5:2")
        compare(Streams.clock(65), "1:05")
        compare(Streams.clock(3725), "1:02:05")
    }
    function test_kitsu() {
        compare(Streams.kitsuIdFrom({ included: [{ type: "anime", id: "12" }] }), "12")
        compare(Streams.kitsuIdFrom({ included: [{ type: "manga", id: "12" }] }), "")
    }
}
