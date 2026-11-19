pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// What was copied: the list on one side, the marked entry read in full on the other. The search keeps the keys: the arrows
// walk the rows, Enter copies the marked one and closes.
Item {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 0
    property bool open: false

    implicitWidth: NihilStyle.s(980)
    implicitHeight: Math.min(NihilStyle.s(620), root.room)

    property string query: ""
    property string kind: "all"
    property bool armed: false

    readonly property var pins: {
        const words = root.query.trim().toLowerCase()
        if (root.kind === "image")
            return []
        return (Cliphist.pinned ?? [])
            .filter(text => words.length === 0 || String(text).toLowerCase().includes(words))
            .map(text => ({ pinned: true, text: text, entry: "" }))
    }
    readonly property var history: {
        if (root.kind === "pinned")
            return []
        const words = root.query.trim()
        const found = words.length > 0 ? Cliphist.fuzzyQuery(words) : Cliphist.entries
        return found.filter(entry => Cliphist.pinnedTextFor(entry).length === 0)
            .filter(entry => root.kind === "all" || Cliphist.entryIsImage(entry) === (root.kind === "image"))
            .map(entry => ({ pinned: false, text: "", entry: entry }))
    }
    readonly property var rows: [...root.pins, ...root.history]

    onOpenChanged: {
        if (!root.open)
            return
        root.query = ""
        root.kind = "all"
        root.armed = false
        search.clear()
        search.take()
        list.currentIndex = 0
        Cliphist.refresh()
    }

    function use(row: var): void {
        if (!row)
            return
        if (row.pinned)
            Quickshell.clipboardText = row.text
        else
            Cliphist.copy(row.entry)
        GlobalStates.clipboardOpen = false
    }

    Timer {
        interval: 3000
        running: root.armed
        onTriggered: root.armed = false
    }

    Item {
        id: sheet

        readonly property real inset: NihilStyle.s(20)

        x: sheet.inset
        y: root.flipped ? NihilStyle.s(40) : NihilStyle.s(16)
        width: root.width - sheet.inset * 2
        height: root.height - NihilStyle.s(56)

        Item {
            id: side
            width: NihilStyle.s(400)
            height: sheet.height

            NField {
                id: search
                width: side.width
                height: NihilStyle.s(50)
                glyph: "search"
                placeholder: Translation.tr("Search what you copied")
                clearable: true
                onEdited: text => {
                    root.query = text
                    list.currentIndex = 0
                }
                onStepped: by => list.currentIndex = NihilStyle.clamp(list.currentIndex + by, 0, Math.max(0, list.count - 1))
                onEntered: root.use(root.rows[list.currentIndex])
            }

            NSegmented {
                id: kinds
                y: search.height + NihilStyle.s(10)
                width: side.width
                options: [
                    { value: "all", label: Translation.tr("All") },
                    { value: "text", label: Translation.tr("Text") },
                    { value: "image", label: Translation.tr("Images") },
                    { value: "pinned", label: Translation.tr("Pinned") }
                ]
                current: root.kind
                onPicked: value => {
                    root.kind = value
                    list.currentIndex = 0
                }
            }

            ListView {
                id: list
                y: kinds.y + kinds.height + NihilStyle.s(10)
                width: side.width
                height: side.height - y
                clip: true
                spacing: NihilStyle.s(2)
                boundsBehavior: Flickable.StopAtBounds
                model: root.rows
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)

                delegate: ClipRow {
                    id: clip
                    required property var modelData
                    required property int index
                    width: list.width
                    row: clip.modelData
                    marked: list.currentIndex === clip.index
                    onUsed: root.use(clip.modelData)
                    onContainsMouseChanged: if (clip.containsMouse) list.currentIndex = clip.index
                }
            }

            Column {
                anchors.centerIn: list
                width: list.width
                visible: list.count === 0
                spacing: NihilStyle.s(6)

                NIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: root.query.length > 0 ? "search_off" : "clipboard"
                    size: NihilStyle.s(32)
                    color: NihilStyle.inkSoft
                }
                NText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.query.length > 0 ? Translation.tr("Nothing matches") : Translation.tr("Nothing copied yet")
                    font.pixelSize: NihilStyle.textLarge
                }
                NText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    text: root.query.length > 0 ? Translation.tr("Try another word") : Translation.tr("What you copy lands here")
                    color: NihilStyle.inkSoft
                }
            }
        }

        // What the marked entry holds, and what can be done with it.
        Rectangle {
            id: plate

            readonly property var row: root.rows[list.currentIndex] ?? null
            readonly property real pad: NihilStyle.s(22)

            x: side.width + NihilStyle.s(16)
            width: sheet.width - x
            height: sheet.height
            radius: NihilStyle.r(26)
            color: NihilStyle.piece

            ClipPreview {
                id: preview
                x: plate.pad
                y: plate.pad
                width: plate.width - plate.pad * 2
                height: plate.height - plate.pad * 2 - actions.height - NihilStyle.s(14)
                row: plate.row
                live: root.open
            }

            Item {
                id: actions
                x: plate.pad
                y: plate.height - plate.pad - height
                width: plate.width - plate.pad * 2
                height: NihilStyle.s(42)
                visible: plate.row !== null

                Row {
                    spacing: NihilStyle.s(6)
                    NButton {
                        height: actions.height
                        icon: "content_copy"
                        label: Translation.tr("Copy")
                        lit: true
                        onClicked: root.use(plate.row)
                    }
                    NButton {
                        height: actions.height
                        visible: plate.row !== null && (plate.row.pinned || Cliphist.isPinnable(plate.row.entry))
                        icon: "pin"
                        label: plate.row?.pinned ? Translation.tr("Unpin") : Translation.tr("Pin")
                        onClicked: plate.row.pinned ? Cliphist.unpin(plate.row.text) : Cliphist.pinEntry(plate.row.entry)
                    }
                    NButton {
                        width: actions.height
                        height: actions.height
                        visible: plate.row !== null && !plate.row.pinned
                        icon: "delete"
                        Accessible.name: Translation.tr("Delete")
                        onClicked: Cliphist.deleteEntry(plate.row.entry)
                    }
                }
                NButton {
                    anchors.right: parent.right
                    height: actions.height
                    visible: Cliphist.entries.length > 0
                    icon: "delete_sweep"
                    label: root.armed ? Translation.tr("Clear all") : ""
                    tone: "transparent"
                    Accessible.name: Translation.tr("Clear all")
                    onClicked: {
                        if (!root.armed) {
                            root.armed = true
                            return
                        }
                        root.armed = false
                        Cliphist.wipe()
                    }
                }
            }
        }
    }
}
