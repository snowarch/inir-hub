pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The Anime Corner's own state: whether it is open, where it opens, and the person's options. The options live in
// ~/.config/inir/plugins/anime-corner.json, never in config.json, so removing the Corner leaves the settings as they were.
Singleton {
    id: root

    property bool open: false
    // Where the next open lands: a place, "anime:<AniList id>" or "settings", and a search to type.
    property string place: ""
    property string query: ""
    // Opened once this session: watching and the list wake only then.
    property bool used: false
    onOpenChanged: if (root.open) root.used = true

    readonly property alias options: adapter
    readonly property bool ready: file.loaded
    // One write per change, from any page.
    function set(name: string, value: var): void {
        if (adapter[name] === value) return
        adapter[name] = value
    }

    FileView {
        id: file
        path: Directories.pluginFile("anime-corner")
        watchChanges: true
        onFileChanged: file.reload()
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter() }
        JsonAdapter {
            id: adapter
            // The language they speak (ja, en, es-419, pt-BR, fr, de, it, ru, hi, ta, te) and, with Japanese, the
            // subtitles in the picture ("auto" follows iNiR's language).
            property string audio: "ja"
            property string subs: "auto"
            // "ask" lists every site; "auto" plays the best; a site id plays from it first.
            property string source: "ask"
            property string anilistClientId: ""
            property string malClientId: ""
            property string anilistUser: ""
            property string malUser: ""
            property bool syncProgress: true
            property bool notify: false
            // The Corner's layout and host, like Settings' (classic, folio, pocket, drawer; overlay or window).
            property string layout: ""
            property bool windowed: false
        }
    }
}
