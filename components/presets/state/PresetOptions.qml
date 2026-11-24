pragma Singleton
pragma ComponentBehavior: Bound

// Presets' own options, in ~/.config/inir/plugins/presets.json.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import "../logic/StoreLogic.js" as Store

Singleton {
    id: root
    property alias root: adapter.root
    property alias lastFolder: adapter.lastFolder
    property alias applyWallpaper: adapter.applyWallpaper
    // Where the presets live: the chosen absolute folder, or ~/.local/share/inir-presets.
    readonly property string rootDir: Store.validRoot(adapter.root) ? adapter.root : Quickshell.env("HOME") + "/.local/share/inir-presets"

    function set(name: string, value: var): void {
        if (adapter[name] !== value) adapter[name] = value;
    }

    FileView {
        id: file
        path: Directories.pluginFile("presets")
        printErrors: false
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter(); }
        JsonAdapter {
            id: adapter
            property string root: ""
            property string lastFolder: ""
            property bool applyWallpaper: true
        }
    }
}
