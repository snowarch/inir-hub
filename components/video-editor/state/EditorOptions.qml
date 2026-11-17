// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import Quickshell.Io
import qs.modules.common

FileView {
    property alias showEditPrompt: options.showEditPrompt
    property alias openInLosslessCut: options.openInLosslessCut
    path: Directories.pluginFile("video-editor")
    watchChanges: true
    onFileChanged: reload()
    printErrors: false
    onAdapterUpdated: writeAdapter()
    onLoadFailed: error => { if (error === FileViewError.FileNotFound) writeAdapter(); }
    JsonAdapter {
        id: options
        property bool showEditPrompt: true
        property bool openInLosslessCut: false
    }
}
