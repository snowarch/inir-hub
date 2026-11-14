import QtQuick
import QtTest
import "../state/subtitles.js" as Subs
TestCase {
    name: "SubtitleFixtures"
    function test_responses() {
        const items = Subs.searchResults({data:[{attributes:{language:"es", release:"A", files:[{file_id:42}]}}, {attributes:{files:[]}}]}, "es")
        compare(items.length, 1)
        compare(items[0].fileId, 42)
        compare(items[0].lang, "es")
        compare(Subs.searchResults(null, "es").length, 0)
        compare(Subs.downloadLink({link:"https://example.com/a.srt"}), "https://example.com/a.srt")
        compare(Subs.downloadLink({link:"file:///etc/passwd"}), "")
    }
    function test_status() {
        compare(Subs.statusError(200), "")
        compare(Subs.statusError(429), "busy")
        compare(Subs.statusError(503), "network")
        compare(Subs.statusError(0), "network")
    }
}
