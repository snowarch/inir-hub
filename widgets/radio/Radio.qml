pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import "radio.js" as R

// The one radio every face shows: the desktop card on each screen, the Island line and the Waffle card all read and
// steer this, so two faces never play two streams. It plays until the person pauses it (a face closing, like the
// Island or Waffle's panel, keeps the music going) and stops when the widget is removed.
Singleton {
    id: root

    readonly property var genres: R.genres(CustomWidgets.getConfigValue("radio", "genres", ""))
    readonly property real volume: Math.max(0, Math.min(100, Number(CustomWidgets.getConfigValue("radio", "volume", 60))))
    // Stations from the person's own country come after the rest: the point is to hear a place.
    readonly property string home: String(Qt.locale().name.split("_")[1] ?? "").toUpperCase()

    property var stations: []
    property int index: -1
    readonly property var current: root.index >= 0 && root.index < root.stations.length ? root.stations[root.index] : null
    property string tag: ""
    property bool searching: false
    property string problem: ""
    property var recent: []
    property int deadInRow: 0

    readonly property string phase: root.problem.length > 0 ? "failed"
        : root.searching ? "searching"
        : player.active && !player.audible ? "tuning"
        : player.active ? "playing"
        : root.current ? "stopped" : "idle"
    readonly property bool live: player.active
    readonly property string onAir: player.onAir
    readonly property string line: R.status(root.phase, player.onAir, root.tag, root.problem)
    readonly property string place: R.where(root.current)
    readonly property string flag: R.flag(root.current?.code ?? "")

    // Play, or stop. A live stream paused falls behind the broadcast, so pausing stops and playing tunes back in.
    function playPause(): void {
        if (player.active) player.stop()
        else if (root.current) root.playAt(root.index)
        else root.tune()
    }
    function next(): void {
        if (root.searching) return
        if (root.index + 1 < root.stations.length) root.playAt(root.index + 1)
        else root.tune()
    }

    function tune(): void { root.tuneTry(0) }
    function tuneTry(tries: int): void {
        root.problem = ""
        const next = R.nextGenre(root.genres, root.tag)
        root.tag = next
        root.searching = true
        browser.search(next, root.recent, root.home, (ok, found) => {
            if (root.tag !== next) return
            root.searching = false
            if (!ok) { root.problem = "Radio Browser can't be reached right now"; return }
            if (found.length === 0) {
                if (tries < 3) { root.tuneTry(tries + 1); return }
                root.problem = `Nothing plays ${next} right now`
                return
            }
            root.stations = found
            root.playAt(0)
        })
    }
    function playAt(i: int): void {
        root.problem = ""
        root.index = i
        const s = root.stations[i]
        player.play(s)
        browser.counted(s.uuid)
        root.recent = root.recent.filter(u => u !== s.uuid).concat([s.uuid]).slice(-120)
    }
    function skipDead(): void {
        if (player.failure === "mpv") { root.problem = "mpv isn't installed: the radio plays through it"; return }
        if (++root.deadInRow >= 6) {
            root.deadInRow = 0
            root.problem = "Stations aren't answering. Check your connection"
            return
        }
        root.next()
    }
    Connections {
        target: player
        function onAudibleChanged(): void { if (player.audible) root.deadInRow = 0 }
    }

    // Removed from the Hub: nothing is left to stop it, so it stops itself.
    readonly property bool installed: !CustomWidgets.ready || CustomWidgets.widgets.some(w => w.id === "radio")
    onInstalledChanged: if (!root.installed) player.stop()

    RadioBrowser { id: browser }
    RadioPlayer {
        id: player
        volume: root.volume
        onDead: root.skipDead()
    }
}
