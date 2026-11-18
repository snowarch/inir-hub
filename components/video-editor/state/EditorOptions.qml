// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import qs.modules.common

Singleton {
    id: root
    readonly property alias options: adapter
    property alias showEditPrompt: adapter.showEditPrompt
    property alias openInLosslessCut: adapter.openInLosslessCut
    property alias windowed: adapter.windowed
    property alias style: adapter.style

    function set(name: string, value: var): void {
        if (adapter[name] === value) return;
        adapter[name] = value;
    }
    function reload(): void { file.reload(); }

    FileView {
        id: file
        path: Directories.pluginFile("video-editor")
        watchChanges: true
        onFileChanged: file.reload()
        printErrors: false
        onAdapterUpdated: file.writeAdapter()
        onLoadFailed: error => { if (error === FileViewError.FileNotFound) file.writeAdapter(); }
        JsonAdapter {
            id: adapter
            property bool showEditPrompt: true
            property bool openInLosslessCut: false
            property bool windowed: true
            property string style: ""
        }
    }
}
