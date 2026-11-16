import QtQuick
import QtTest
import "../state/subtitles.js" as Subs
TestCase {
    name: "SubtitleFixtures"
    function test_languageSelection() {
        const items = [{lang: "es", name: "Spanish"}, {lang: "eng", name: "English"}, {lang: "xyz", name: "Custom"}]
        compare(Subs.findLanguage(items, "spa").name, "Spanish")
        compare(Subs.findLanguage(items, "en").name, "English")
        compare(Subs.findLanguage(items, "XYZ").name, "Custom")
        compare(Subs.findLanguage(items, "fra"), null)
        compare(Subs.findLanguage(items, ""), null)
        compare(Subs.findLanguage([], "spa"), null)
        compare(Subs.languageLabel("es"), "Español (es)")
        compare(Subs.languageLabel("xyz"), "xyz")
        compare(Subs.preferredSelection(items, "eng", "spa", false, true).name, "English")
        compare(Subs.preferredSelection(items, "fra", "spa", false, true).name, "Spanish")
        compare(Subs.preferredSelection(items, "fra", "spa", true, true), null)
        compare(Subs.preferredSelection(items, "eng", "spa", false, false), null)
    }
    function test_responses() {
        const items = Subs.searchResults({data:[{attributes:{language:"es", release:"A", hearing_impaired:true, files:[{file_id:42}]}}, {attributes:{files:[]}}]}, "es")
        compare(items.length, 1)
        compare(items[0].fileId, 42)
        compare(items[0].lang, "es")
        compare(items[0].name, "A")
        compare(items[0].hearingImpaired, true)
        compare(Subs.searchResults({data:[{attributes:{hearing_impaired:"true", files:[{file_id:1}]}}]}, "en")[0].hearingImpaired, false)
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
