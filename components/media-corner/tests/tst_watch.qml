import QtQuick
import QtTest
import "../state/watch.js" as Watch

TestCase {
    name: "Watch"

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
        const first = Watch.toggleWatchlist({}, "tt1", show)
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
