pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The Movie Corner's own state: whether it is open, where it opens, the person's options and the titles they follow.
// All of it lives in ~/.config/inir/plugins/movie-corner.json, never in config.json, so removing the Corner leaves the
// settings as they were.
Singleton {
    id: root

    property bool open: false
    // Where the next open lands: a place, "title:<movie|series>:<IMDb id>" or "settings", and a search to type.
    property string place: ""
    property string query: ""
    // Opened once this session: watching wakes only then.
    property bool used: false
    onOpenChanged: if (root.open) root.used = true

    readonly property alias options: adapter
    readonly property bool ready: file.loaded
    // One write per change, from any page.
    function set(name: string, value: var): void {
        if (adapter[name] === value) return
        adapter[name] = value
    }

    // What the person follows: { id, kind, title, image, year }, newest first.
    readonly property var following: Array.from(adapter.following ?? [])
    function follows(id: string): bool { return root.following.some(entry => entry.id === id) }
    function toggleFollow(show: var): void {
        const id = String(show?.id ?? "")
        if (id.length === 0) return
        adapter.following = root.follows(id) ? root.following.filter(entry => entry.id !== id)
            : [{ id, kind: String(show.kind ?? "movie"), title: String(show.title ?? ""), image: String(show.image ?? ""), year: String(show.year ?? "") }].concat(root.following)
    }

    FileView {
        id: file
        path: Directories.pluginFile("movie-corner")
        watchChanges: true
        onFileChanged: file.reload()
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter() }
        JsonAdapter {
            id: adapter
            // The spoken language ("original", "es-419", "es-ES") and, with the original, the subtitles' ("auto"
            // follows iNiR's language; "none" shows none).
            property string audio: "original"
            property string subs: "auto"
            // "ask" lists every source; "auto" plays the best; a site id plays from it first.
            property string source: "ask"
            // The Corner's layout and host, like Settings' (classic, folio, pocket, drawer; overlay or window).
            property string layout: ""
            property bool windowed: false
            // An entry in the app launcher (and so the Dock) that opens the Corner.
            property bool launcher: true
            // The Stremio add-ons the person added, as JSON text ([{url, name, types, audio}]).
            property string addons: "[]"
            property var following: []
        }
    }
}
