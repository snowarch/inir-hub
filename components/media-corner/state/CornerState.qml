pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

// The Media Corner's own state: whether it is open, where it opens, and the person's options. The options live in
// ~/.config/inir/plugins/media-corner.json, never in config.json, so removing it leaves the settings as they were.
Singleton {
    id: root

    property bool open: false
    // Where the next open lands: a place ("anime:top", "movie:series"…), "anime:<AniList id>",
    // "title:<movie|series>:<IMDb id>", and a search to type.
    property string place: ""
    property string query: ""

    readonly property alias options: adapter
    readonly property bool ready: file.loaded
    function set(name: string, value: var): void {
        if (adapter[name] === value) return
        adapter[name] = value
    }

    FileView {
        id: file
        path: Directories.pluginFile("media-corner")
        watchChanges: true
        onFileChanged: file.reload()
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter() }
        JsonAdapter {
            id: adapter
            // The layout (classic, folio, pocket, drawer; empty follows Settings') and the host (overlay or window).
            property string layout: ""
            property bool windowed: false
        }
    }
}
