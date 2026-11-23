pragma Singleton
pragma ComponentBehavior: Bound

// Ink Notes' own options, in ~/.config/inir/plugins/inknotes.json.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common
import "../logic/NotesLogic.js" as Logic

Singleton {
    id: root
    property alias location: adapter.location
    property alias customPath: adapter.customPath
    property alias sort: adapter.sort
    property alias trashDays: adapter.trashDays
    property alias pins: adapter.pins
    property alias lastNote: adapter.lastNote
    property alias fonts: adapter.fonts
    property alias zoom: adapter.zoom
    property alias showFolders: adapter.showFolders
    property alias showList: adapter.showList
    property alias showToolbar: adapter.showToolbar
    readonly property string rootPath: Logic.rootFor(adapter.location, adapter.customPath, Directories.documentsPath, Directories.stateUserPath)

    function set(name: string, value: var): void {
        if (adapter[name] !== value) adapter[name] = value;
    }
    // A note or folder was renamed or moved: what is remembered about it follows.
    function moved(from: string, to: string): void {
        root.pins = root.pins.map(k => Logic.movedKey(k, from, to));
        const next = {};
        for (const k in root.fonts) next[Logic.movedKey(k, from, to)] = root.fonts[k];
        root.fonts = next;
        if (root.lastNote) root.lastNote = Logic.movedKey(root.lastNote, from, to);
    }
    function togglePin(rel: string): void {
        root.pins = root.pins.includes(rel) ? root.pins.filter(k => k !== rel) : root.pins.concat([rel]);
    }
    function fontOf(rel: string): var { return root.fonts[rel] ?? ({ family: "default", size: "default" }) }
    function setFont(rel: string, key: string, value: string): void {
        const next = Object.assign({}, root.fonts);
        next[rel] = Object.assign({}, root.fontOf(rel), { [key]: value });
        root.fonts = next;
    }

    FileView {
        id: file
        path: Directories.pluginFile("inknotes")
        printErrors: false
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter(); }
        JsonAdapter {
            id: adapter
            property string location: "documents"
            property string customPath: ""
            property string sort: "edited"
            property int trashDays: 30
            property var pins: []
            property string lastNote: ""
            property var fonts: ({})
            property int zoom: 100
            property bool showFolders: true
            property bool showList: true
            property bool showToolbar: true
        }
    }
}
