pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import "radio.js" as R

// The one radio every face shows: the desktop card on each screen, the Island line, the Waffle card and the tuner
// all read and steer this, so two faces never play two streams. It plays until the person stops it (a face closing
// keeps the music going) and stops when the widget is removed.
Singleton {
    id: root

    // ── What the person keeps (the widget's own config: survives updates) ──
    readonly property var genres: R.genres(CustomWidgets.getConfigValue("radio", "genres", ""))
    readonly property real volume: Math.max(0, Math.min(100, Number(CustomWidgets.getConfigValue("radio", "volume", 60))))
    readonly property bool muted: CustomWidgets.getConfigValue("radio", "muted", false) === true
    readonly property var favourites: root.stationsIn(CustomWidgets.getConfigValue("radio", "favourites", []))
    readonly property var recent: root.stationsIn(CustomWidgets.getConfigValue("radio", "recent", []))
    readonly property var favouriteIds: root.favourites.reduce((all, s) => { all[s.uuid] = true; return all }, {})
    // Stations from the person's own country come after the rest in the discovery tune: the point is to hear a place.
    readonly property string home: String(Qt.locale().name.split("_")[1] ?? "").toUpperCase()

    function stationsIn(value: var): var {
        return Array.isArray(value) ? value.filter(s => s && typeof s.url === "string" && s.url.length > 0 && typeof s.uuid === "string")
            .map(s => Object.assign({}, s, { name: R.cleanName(s.name) })) : []
    }

    // ── What plays ──
    property var stations: []          // the list next steps through: the one the station was picked from
    property int index: -1
    property var current: null
    property string tag: ""            // the discovery tune's genre; empty when the person picked the station
    property bool searching: false
    property string problem: ""
    property var heard: []             // uuids the discovery tune skips this session
    property int deadInRow: 0

    readonly property string phase: root.problem.length > 0 ? "failed"
        : root.searching ? "searching"
        : player.active && player.paused ? "stopped"
        : player.active && !player.audible ? "tuning"
        : player.active ? "playing"
        : root.current ? "stopped" : "idle"
    readonly property bool playing: root.phase === "playing"
    readonly property bool waiting: root.phase === "searching" || root.phase === "tuning"
    readonly property string onAir: player.onAir
    readonly property string place: R.where(root.current)
    readonly property string flag: R.flag(root.current?.code ?? "")
    readonly property string logo: root.current?.logo ?? ""
    // The stream publishes no cover of its own: the shell's player shows the station's logo for it.
    onCurrentChanged: if (root.current?.logo && typeof MprisController.offerCover === "function")
        MprisController.offerCover(String(root.current.url), String(root.current.logo))
    readonly property bool kept: !!root.current && root.favouriteIds[root.current.uuid] === true
    // What the station's line says: the song when the station names it, else what is happening, in words.
    readonly property string line: {
        switch (root.phase) {
        case "failed": return root.problem
        case "searching": return Translation.tr("Looking for %1 somewhere…").arg(root.tag)
        case "tuning": return Translation.tr("Tuning in…")
        case "playing": return root.onAir.length > 0 ? root.onAir : root.tag.length > 0 ? root.tag : Translation.tr("Live")
        case "stopped": return Translation.tr("Stopped · play tunes back in live")
        default: return root.recent.length > 0 ? Translation.tr("Play picks up %1").arg(root.recent[0].name)
            : Translation.tr("Live stations from anywhere in the world")
        }
    }

    // Play, or stop. A live stream paused falls behind the broadcast, so stopping stops and playing tunes back in.
    function playPause(): void {
        if (player.active && !player.paused) player.stop()
        else if (root.current) root.playAt(root.index)
        else if (root.recent.length > 0) root.play(root.recent[0], root.recent)
        else root.tune()
    }
    function stop(): void { player.stop() }
    // The next station of the list it came from; past its end, or with no list, the discovery tune.
    function next(): void {
        if (root.searching) return
        if (root.index + 1 < root.stations.length) root.playAt(root.index + 1)
        else root.tune()
    }
    // A station picked by the person, from a list the next button then walks.
    function play(station: var, from: var): void {
        const list = Array.isArray(from) && from.length > 0 ? from : [station]
        const at = list.findIndex(s => s.uuid === station.uuid)
        root.tag = ""
        root.stations = at >= 0 ? list : [station].concat(list)
        root.playAt(Math.max(0, at))
    }
    function playAt(i: int): void {
        root.problem = ""
        root.searching = false
        root.index = i
        const s = root.stations[i]
        root.current = s
        player.play(s)
        browser.counted(s.uuid)
        root.heard = root.heard.filter(u => u !== s.uuid).concat([s.uuid]).slice(-120)
        CustomWidgets.setConfigValue("radio", "recent", [s].concat(root.recent.filter(r => r.uuid !== s.uuid)).slice(0, 24))
    }

    // The discovery tune: a station somewhere playing one of the person's genres, or anything at all.
    function tune(): void { root.tuneTry(0) }
    function tuneTry(tries: int): void {
        root.problem = ""
        const next = R.nextGenre(root.genres, root.tag)
        root.tag = next
        root.searching = true
        browser.discover(next, root.heard, root.home, (ok, found) => {
            if (root.tag !== next || !root.searching) return
            root.searching = false
            if (!ok) { root.problem = Translation.tr("Radio Browser can't be reached. Check your connection"); return }
            if (found.length === 0) {
                if (tries < 3) { root.tuneTry(tries + 1); return }
                root.problem = Translation.tr("Nothing plays %1 right now").arg(next)
                return
            }
            root.stations = found
            root.playAt(0)
        })
    }

    function skipDead(): void {
        if (player.failure === "mpv") { root.problem = Translation.tr("mpv isn't installed: the radio plays through it"); return }
        const gone = root.current?.name ?? ""
        if (++root.deadInRow >= 6 || root.stations.length <= 1) {
            root.deadInRow = 0
            root.problem = root.stations.length <= 1 && gone.length > 0
                ? Translation.tr("%1 isn't answering right now").arg(gone)
                : Translation.tr("Stations aren't answering. Check your connection")
            return
        }
        root.skipped = gone
        skippedShown.restart()
        root.next()
    }
    // A dead station stepped over is said for a moment, so the change of station is never a surprise.
    property string skipped: ""
    Timer { id: skippedShown; interval: 4000; onTriggered: root.skipped = "" }
    Connections {
        target: player
        function onAudibleChanged(): void { if (player.audible) root.deadInRow = 0 }
    }

    // ── Keeping ──
    function isFavourite(uuid: string): bool { return root.favouriteIds[uuid] === true }
    function toggleFavourite(station: var): void {
        if (!station) return
        const next = root.isFavourite(station.uuid) ? root.favourites.filter(s => s.uuid !== station.uuid)
            : root.favourites.concat([station])
        CustomWidgets.setConfigValue("radio", "favourites", next)
    }
    function forgetRecent(): void { CustomWidgets.setConfigValue("radio", "recent", []) }

    // ── Volume: heard at once, written once the hand stops ──
    property real liveVolume: root.volume
    onVolumeChanged: root.liveVolume = root.volume
    function setVolume(v: real): void {
        root.liveVolume = Math.max(0, Math.min(100, Math.round(v)))
        if (root.muted && root.liveVolume > 0) CustomWidgets.setConfigValue("radio", "muted", false)
        volumeWrite.restart()
    }
    function nudgeVolume(steps: real): void { root.setVolume(root.liveVolume + steps * 5) }
    function toggleMute(): void { CustomWidgets.setConfigValue("radio", "muted", !root.muted) }
    Timer {
        id: volumeWrite
        interval: 600
        onTriggered: CustomWidgets.setConfigValue("radio", "volume", root.liveVolume)
    }

    // ── The tuner: one window, on the screen of the face that opened it, drawn in that face's family ──
    property bool tunerOpen: false
    property var tunerScreen: null
    property var tunerLook: null
    function openTuner(screen: var, look: var): void {
        const where = screen ?? Quickshell.screens[0] ?? null
        if (root.tunerOpen && where === root.tunerScreen) { root.closeTuner(); return }
        // A layer window never moves to another screen: the one open goes, a new one comes on the next turn.
        const moving = root.tunerOpen
        root.tunerOpen = false
        root.tunerScreen = where
        root.tunerLook = look
        if (moving) reopen.restart()
        else root.tunerOpen = where !== null && look !== null
    }
    Timer { id: reopen; interval: 0; onTriggered: root.tunerOpen = root.tunerScreen !== null && root.tunerLook !== null }
    function closeTuner(): void { root.tunerOpen = false }
    LazyLoader {
        active: root.tunerOpen
        RadioTuner {
            screen: root.tunerScreen
            look: root.tunerLook
            browser: browser
            onDismissed: root.closeTuner()
        }
    }

    // Removed from the Hub, or replaced by a newer copy (an update, a reload loads the widget from a new folder and
    // with it a new Radio): nothing is left to stop this one, so it stops itself.
    readonly property string folder: String(Qt.resolvedUrl("."))
    readonly property bool installed: !CustomWidgets.ready
        || CustomWidgets.widgets.some(w => w.id === "radio" && String(w.qmlPath).indexOf(root.folder) === 0)
    onInstalledChanged: if (!root.installed) { player.stop(); root.closeTuner() }

    RadioBrowser { id: browser }
    RadioPlayer {
        id: player
        volume: root.liveVolume
        muted: root.muted
        onDead: root.skipDead()
    }

    /// The radio widget: play, stop, step to the next station and open the tuner, for keybinds and media keys.
    IpcHandler {
        target: "radio"
        // A replaced copy hands the target to the new one.
        enabled: root.installed

        /// Plays the last station (or a discovered one), or stops what plays. Returns the phase after it.
        function toggle(): string { root.playPause(); return root.phase }
        /// The next station of the list it was picked from, else a discovered one.
        function next(): string { root.next(); return root.phase }
        /// Stops the radio.
        function stop(): string { root.stop(); return root.phase }
        /// Stars or unstars the station that plays. Returns whether it is kept now.
        function keep(): bool { root.toggleFavourite(root.current); return root.kept }
        /// What plays: the phase, the station and what it announces.
        function status(): string {
            return root.current ? `${root.phase}\t${root.current.name}\t${root.place}\t${root.onAir}` : root.phase
        }
    }
}
