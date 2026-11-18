pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// What was copied, as one block over the bar: the pins first, then the history newest first. The search keeps the
// keys: arrows walk the rows, Enter copies the one marked and closes.
NPopup {
    id: root

    open: NihilState.clipboardOpen
    namespace: "nihil:clipboard"
    onDismissed: GlobalStates.clipboardOpen = false

    property string query: ""
    readonly property var pins: {
        const words = root.query.trim().toLowerCase()
        return (Cliphist.pinned ?? []).filter(text => words.length === 0 || String(text).toLowerCase().includes(words))
            .map(text => ({ pinned: true, text: text, entry: "" }))
    }
    readonly property var history: {
        const words = root.query.trim()
        const found = words.length > 0 ? Cliphist.fuzzyQuery(words) : Cliphist.entries
        return found.filter(entry => Cliphist.pinnedTextFor(entry).length === 0)
            .map(entry => ({ pinned: false, text: "", entry: entry }))
    }
    readonly property var rows: [...root.pins, ...root.history]

    onOpenChanged: {
        if (!root.open) return
        root.query = ""
        search.clear()
        search.take()
        list.currentIndex = 0
        Cliphist.refresh()
    }

    function use(row: var): void {
        if (!row) return
        if (row.pinned) Quickshell.clipboardText = row.text
        else Cliphist.copy(row.entry)
        GlobalStates.clipboardOpen = false
    }

    NRack {
        id: rack
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        readonly property real g: NihilStyle.seam
        width: Math.min(NihilStyle.s(500), root.width - NihilStyle.edge * 2)
        height: Math.min(NihilStyle.s(620), room)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        Row {
            id: head
            height: NihilStyle.s(80)
            spacing: rack.g
            NTile {
                id: title
                width: rack.width - wipe.width - rack.g
                height: head.height
                paper: true
                caption: root.rows.length + " " + Translation.tr("Kept")
                NText {
                    x: title.pad
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(6)
                    text: Translation.tr("Clipboard")
                    font.pixelSize: NihilStyle.textTitle
                    font.weight: Font.Black
                    color: title.ink
                }
            }
            NConfirm {
                id: wipe
                width: NihilStyle.s(96)
                height: head.height
                square: true
                interactive: Cliphist.entries.length > 0
                glyph: "delete_sweep"
                label: Translation.tr("Clear")
                onConfirmed: Cliphist.wipe()
            }
        }

        NField {
            id: search
            y: head.height + rack.g
            width: rack.width
            height: NihilStyle.s(56)
            glyph: "search"
            placeholder: Translation.tr("Search what you copied")
            clearable: true
            onEdited: text => { root.query = text; list.currentIndex = 0 }
            onStepped: by => list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + by))
            onEntered: root.use(root.rows[list.currentIndex])
        }

        NTile {
            id: sheet
            y: search.y + search.height + rack.g
            width: rack.width
            height: rack.height - y

            ListView {
                id: list
                x: NihilStyle.s(6)
                y: NihilStyle.s(6)
                width: sheet.width - NihilStyle.s(12)
                height: sheet.height - NihilStyle.s(12)
                clip: true
                spacing: NihilStyle.seam
                boundsBehavior: Flickable.StopAtBounds
                model: root.rows
                highlightFollowsCurrentItem: false
                onCurrentIndexChanged: list.positionViewAtIndex(list.currentIndex, ListView.Contain)
                delegate: ClipRow {
                    required property var modelData
                    required property int index
                    width: list.width
                    row: modelData
                    marked: list.currentIndex === index
                    onUsed: root.use(modelData)
                    onHoveredChanged: if (hovered) list.currentIndex = index
                }
            }

            NEmpty {
                anchors.centerIn: parent
                width: sheet.width - NihilStyle.s(40)
                visible: list.count === 0
                glyph: root.query.length > 0 ? "search_off" : "content_paste"
                title: root.query.length > 0 ? Translation.tr("Nothing matches") : Translation.tr("Nothing copied yet")
                line: root.query.length > 0 ? Translation.tr("Try another word") : Translation.tr("What you copy lands here")
            }
        }
    }
}
