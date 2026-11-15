import QtQuick
import QtTest
import "../state/schedule.js" as Schedule

TestCase {
    name: "Schedule"
    function test_onlySavedSeriesWithValidIds() {
        compare(Schedule.savedIds({ a: { id: 5, kind: "anime" }, b: { id: 7, kind: "anime", film: true }, c: { id: "tt1", kind: "movie" }, d: { id: "bad", kind: "anime" } }).join(), "5")
    }
    function test_onlyKnownFutureEpisodesSortedAndNoMovies() {
        const items = [
            { id: 1, format: "TV", title: { romaji: "Late" }, nextAiringEpisode: { airingAt: 200, episode: 4 } },
            { id: 2, format: "TV", title: { english: "Early" }, nextAiringEpisode: { airingAt: 120, episode: 3 } },
            { id: 3, format: "MOVIE", nextAiringEpisode: { airingAt: 110, episode: 1 } },
            { id: 4, format: "TV", nextAiringEpisode: { airingAt: 99, episode: 2 } },
            { id: 5, format: "TV", nextAiringEpisode: null }
        ]
        const result = Schedule.upcoming(items, 100)
        compare(result.length, 2)
        compare(result[0].title, "Early")
        compare(result[1].episode, 4)
    }
}
