pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style

// What the marked entry really holds: the whole text or the picture, read from the history once the marks stop moving.
Item {
    id: root

    property var row: null
    property bool live: false

    readonly property bool pinned: root.row?.pinned === true
    readonly property string entry: root.pinned ? "" : String(root.row?.entry ?? "")
    readonly property bool image: root.entry.length > 0 && Cliphist.entryIsImage(root.entry)
    readonly property string file: root.image ? `${Directories.cliphistDecode}/${Cliphist.entryId(root.entry)}` : ""
    readonly property string words: root.pinned ? String(root.row?.text ?? "") : root.read
    property string read: ""
    property string picture: ""

    function load(): void {
        if (!root.live || root.entry.length === 0)
            return
        const decode = Cliphist.decodeCommand(root.entry, 2)
        reader.command = root.image
            ? ["bash", "-c", `mkdir -p "$(dirname "$1")" && { ${decode.script}; } > "$1"`, "clip", root.file].concat(decode.args)
            : ["bash", "-c", `{ ${decode.script}; } | head -c 20000`, "clip", ""].concat(decode.args)
        reader.running = true
    }

    onEntryChanged: {
        root.read = ""
        root.picture = ""
        reader.running = false
        settle.restart()
    }
    onLiveChanged: if (root.live) settle.restart()

    Timer {
        id: settle
        interval: 140
        onTriggered: root.load()
    }
    Process {
        id: reader
        stdout: StdioCollector {
            onStreamFinished: if (!root.image) root.read = text
        }
        onExited: code => {
            if (root.image && code === 0)
                root.picture = "file://" + root.file
        }
    }

    Flickable {
        id: page
        anchors.fill: parent
        visible: !root.image
        clip: true
        contentHeight: body.implicitHeight
        boundsBehavior: Flickable.StopAtBounds
        NText {
            id: body
            width: page.width
            text: root.words
            textFormat: Text.PlainText
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            verticalAlignment: Text.AlignTop
            font.pixelSize: NihilStyle.s(15)
            lineHeight: 1.25
        }
    }
    Image {
        anchors.fill: parent
        visible: root.image
        source: root.picture
        sourceSize.width: Math.round(width * 2)
        fillMode: Image.PreserveAspectFit
        asynchronous: true
        cache: false
    }
}
