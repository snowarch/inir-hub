import QtQuick
import QtTest
import "../state/watch.js" as Watch

TestCase {
    name: "Watch"

    function test_summaryCountsOnlySuppliedEpisodesAndManualMarks() {
        const episodes = [{ episode: 1 }, { episode: 3 }]
        const progress = { "1": { position: 95, duration: 100 } }
        const marks = { "1": false, "3": true, "2": true }
        const result = Watch.summarizeEpisodes(episodes, progress, marks, episode => String(episode.episode))
        compare(result.known, 2)
        compare(result.watched, 1)
        compare(result.next.episode, 1)
        const allSeen = Watch.summarizeEpisodes(episodes, progress, { "3": true }, episode => String(episode.episode))
        compare(allSeen.watched, 2)
        verify(allSeen.next === null)
    }

    function test_fullHistoryGroupsAndPreservesEpisodeKeys() {
        const progress = {
            e1: { at: 10, show: { kind: "series", id: "tt1", title: "Series" }, episode: { season: 1, episode: 1 } },
            e2: { at: 20, show: { kind: "series", id: "tt1", title: "Series" }, episode: { season: 1, episode: 2 } },
            film: { at: 30, show: { kind: "movie", id: "tt2", title: "Film" }, episode: null }
        }
        const rows = Watch.historyRows(progress)
        compare(rows.length, 5)
        compare(rows[0].title, "Film")
        compare(rows[1].key, "film")
        compare(rows[2].title, "Series")
        compare(rows[3].key, "e2")
        compare(rows[4].episode.episode, 1)
    }

    function test_savedOrderingUsesKnownDatesAndOwnTitleActivity() {
        const saved = { a: { id: 1, kind: "anime", title: "Alpha" }, b: { id: 2, kind: "anime", title: "Beta", addedAt: 20 }, c: { id: "tt1", kind: "series", title: "Charlie", addedAt: 10 } }
        const progress = { p: { at: 90, show: { id: "tt1", kind: "series" } }, q: { at: 50, show: { id: 2, kind: "anime" } }, r: { at: 999, show: { id: 1, kind: "series" } } }
        compare(Watch.sortedSavedKeys(saved, progress, "title").join(), "a,b,c")
        compare(Watch.sortedSavedKeys(saved, progress, "added").join(), "b,c,a")
        compare(Watch.sortedSavedKeys(saved, progress, "activity").join(), "c,b,a")
        verify(saved.a.addedAt === undefined)
    }

    function test_invalidWatchlistIsRejectedWithoutChangingInput() {
        for (const raw of ["{", "null", "[]", '{"a": 1}', '{"a": null}', '{"a": []}']) {
            const original = raw
            let failed = false
            try { Watch.parseWatchlist(raw) } catch (e) { failed = true }
            verify(failed, raw)
            compare(raw, original)
        }
        const parsed = Watch.parseWatchlist('{"a":{"id":1,"kind":"anime","title":"Example"}}')
        compare(parsed.a.id, 1)
        compare(parsed.a.title, "Example")
    }

    function test_invalidProgressCannotBeTreatedAsEmpty() {
        for (const invalid of ["{", "null", "[]", '{"a": 1}', '{"a":{"position":"wrong"}}']) {
            let failed = false
            try { Watch.parseProgress(invalid) } catch (e) { failed = true }
            verify(failed, invalid)
        }
        compare(Watch.parseProgress('{"a":{"position":10,"duration":100}}').a.position, 10)
    }

    function test_nextUnseenFindsManuallyUnmarkedEarlierEpisode() {
        const episodes = [{ season: 1, episode: 1 }, { season: 1, episode: 2 }]
        const result = Watch.nextUnseen([{ episodes }], { "1": { at: 10 }, "2": { at: 20 } },
            episode => String(episode.episode), key => key === "2", 0)
        compare(result.episode, 1)
    }

    function test_nextUnseenAdvancesWhenSeasonMarkedManually() {
        const s1e1 = { season: 1, episode: 1 }, s2e1 = { season: 2, episode: 1 }
        const result = Watch.nextUnseen([{ episodes: [s1e1] }, { episodes: [s2e1] }], {},
            episode => `s${episode.season}e${episode.episode}`,
            key => key === "s1e1", 0)
        compare(result.season, 2)
        compare(result.episode, 1)
    }

    function test_manualSeenOverridesCompletionWithoutChangingProgress() {
        const progress = { a: { position: 95, duration: 100 }, b: { position: 25, duration: 100 } }
        verify(Watch.isSeen(progress, {}, "a"))
        verify(!Watch.isSeen(progress, { a: false }, "a"))
        verify(Watch.isSeen(progress, { b: true }, "b"))
        verify(Watch.isSeen(progress, { c: true }, "c"))
        compare(progress.a.position, 95)
        compare(progress.b.position, 25)
        verify(progress.c === undefined)
    }

    function test_matchesSavedLocallyByTitleKindAndTranslatedFormat() {
        const show = { title: "Example Film", kind: "movie", type: "Movie" }
        verify(Watch.matchesSaved(show, " example ", []))
        verify(Watch.matchesSaved(show, "MOVIE", []))
        verify(Watch.matchesSaved(show, "película", ["Película"]))
        verify(!Watch.matchesSaved(show, "series", []))
        verify(Watch.matchesSaved(show, "", []))
    }

    function test_resetProgressKeepsMetadataWithoutMutatingInput() {
        const original = { "tt1": { position: 125, duration: 600, at: 50, show: { id: "tt1" }, episode: null } }
        const result = Watch.resetProgress(original, "tt1")
        compare(result["tt1"].position, 0)
        compare(result["tt1"].duration, 0)
        compare(result["tt1"].at, 50)
        compare(result["tt1"].show.id, "tt1")
        compare(original["tt1"].position, 125)
        verify(result !== original)
    }

    function test_resetMissingProgressIsNoOp() {
        const original = { "tt1": { position: 20, duration: 600 } }
        verify(Watch.resetProgress(original, "tt2") === original)
    }

    function test_watchlistAddsAndRemovesOwnTitleSnapshot() {
        const show = { id: "tt1", kind: "series", title: "Example", type: "TV", film: false, description: "not needed" }
        const first = Watch.toggleWatchlist({}, "tt1", show, 123)
        compare(first.tt1.addedAt, 123)
        compare(first.tt1.id, "tt1")
        compare(first.tt1.kind, "series")
        compare(first.tt1.title, "Example")
        compare(first.tt1.type, "TV")
        compare(first.tt1.film, false)
        verify(first.tt1.description === undefined)
        const second = Watch.toggleWatchlist(first, "tt1", show)
        compare(Object.keys(second).length, 0)
        compare(Object.keys(first).length, 1)
    }

    function test_nextUnseenResumesLatestEpisodeInItsSeason() {
        const s1e1 = { season: 1, episode: 1 }, s1e2 = { season: 1, episode: 2 }
        const s2e1 = { season: 2, episode: 1 }, s2e2 = { season: 2, episode: 2 }
        const groups = [{ episodes: [s1e1, s1e2] }, { episodes: [s2e1, s2e2] }]
        const progress = { "s1e1": { at: 10 }, "s2e1": { at: 20 } }
        const seen = { s1e1: true, s2e1: true }
        const result = Watch.nextUnseen(groups, progress, episode => `s${episode.season}e${episode.episode}`,
            key => Boolean(seen[key]), 0)
        compare(result.season, 2)
        compare(result.episode, 2)
    }

    function test_nextUnseenCanResumeLatestEpisodeWhenNotSeen() {
        const s1e1 = { season: 1, episode: 1 }, s1e2 = { season: 1, episode: 2 }
        const groups = [{ episodes: [s1e1, s1e2] }]
        const progress = { "s1e1": { at: 10 }, "s1e2": { at: 20 } }
        const result = Watch.nextUnseen(groups, progress, episode => `s${episode.season}e${episode.episode}`,
            key => key === "s1e1", 0)
        compare(result.season, 1)
        compare(result.episode, 2)
    }

    function test_nextUnseenCanCrossOnlyToKnownContiguousSeason() {
        const s1e1 = { season: 1, episode: 1 }, s1e2 = { season: 1, episode: 2 }
        const s2e1 = { season: 2, episode: 1 }, s2e2 = { season: 2, episode: 2 }
        const groups = [{ episodes: [s1e1, s1e2] }, { episodes: [s2e1, s2e2] }]
        const progress = { "s1e1": { at: 10 }, "s1e2": { at: 20 } }
        const result = Watch.nextUnseen(groups, progress, episode => `s${episode.season}e${episode.episode}`,
            () => true, 0)
        compare(result.season, 2)
        compare(result.episode, 1)
    }

    function test_nextUnseenDoesNotJumpMissingSeason() {
        const s1e1 = { season: 1, episode: 1 }, s3e1 = { season: 3, episode: 1 }
        const groups = [{ episodes: [s1e1] }, { episodes: [s3e1] }]
        const progress = { "s1e1": { at: 10 } }
        const result = Watch.nextUnseen(groups, progress, episode => `s${episode.season}e${episode.episode}`,
            () => true, 0)
        compare(result, null)
    }

    function test_nextUnseenStartsAtFirstSeasonWhenThereIsNoProgress() {
        const s1e1 = { season: 1, episode: 1 }, s2e1 = { season: 2, episode: 1 }
        const groups = [{ episodes: [s1e1] }, { episodes: [s2e1] }]
        const result = Watch.nextUnseen(groups, {}, episode => `s${episode.season}e${episode.episode}`,
            () => false, 0)
        compare(result.season, 1)
        compare(result.episode, 1)
    }

    function test_sourceNamesFilterAndSort() {
        const streams = [
            { source: "B", name: "z" },
            { source: "A", name: "b" },
            { source: "A", name: "a" }
        ]
        compare(Watch.sourceNames(streams), ["A", "B"])
        compare(Watch.displayedStreams(streams, "A", false).map(s => s.name), ["b", "a"])
        compare(Watch.displayedStreams(streams, "", true).map(s => `${s.source}:${s.name}`), ["A:a", "A:b", "B:z"])
        compare(streams.map(s => s.name), ["z", "b", "a"])
    }

    function test_sourceResultUpdatePreservesOtherStates() {
        const initial = [
            { name: "A", state: "unsupported", count: 0 },
            { name: "B", state: "waiting", count: 0 },
            { name: "C", state: "unidentified", count: 0 }
        ]
        const result = Watch.updateSourceResult(initial, 1, "", 2)
        compare(result[0].state, "unsupported")
        compare(result[1].state, "done")
        compare(result[1].count, 2)
        compare(result[2].state, "unidentified")
        const failed = Watch.updateSourceResult(result, 1, "timeout", 0)
        compare(failed[1].state, "error")
        compare(failed[1].count, 0)
        const nullReply = Watch.updateSourceResult(result, 1, "timeout", null)
        compare(nullReply[1].state, "error")
        compare(nullReply[1].count, 0)
        compare(initial[1].state, "waiting")
        const limited = Watch.updateSourceResult(result, 1, "busy", 0, "120")
        compare(limited[1].state, "limited")
        compare(limited[1].retryAfter, "120")
    }

    function test_sourcePriorityDoesNotDependOnResponseOrder() {
        let streams = Watch.insertSourceStreams([], [{name: "later"}], 1, "Second")
        streams = Watch.insertSourceStreams(streams, [{name: "first"}, {name: "next"}], 0, "Alias")
        compare(streams.map(s => s.name), ["first", "next", "later"])
        compare(streams.map(s => s.source), ["Alias", "Alias", "Second"])
    }

    function test_sourceResultsSeparateMappingFailureFromNoMapping() {
        const paths = [
            { addon: { name: "A" }, path: "" },
            { addon: { name: "B" }, path: "" }
        ]
        const failed = Watch.initialSourceResults(paths, "anime", "", true)
        compare(failed.length, 0)
        const noMapping = Watch.initialSourceResults(paths, "anime", "", false)
        compare(noMapping.length, 2)
        compare(noMapping[0].state, "unidentified")
        const unsupported = Watch.initialSourceResults(paths, "anime", "kitsu-1", false)
        compare(unsupported[0].state, "unsupported")
    }
}
