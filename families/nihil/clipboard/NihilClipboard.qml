pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// What was copied, as one piece over the bar: the pins first, then the history newest first. The search keeps the
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

    NCard {
        id: card
        readonly property real room: root.height - root.edgeTop - root.edgeBottom
        width: Math.min(NihilStyle.s(480), root.width - NihilStyle.edge * 2)
        height: Math.min(NihilStyle.s(600), room)
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop
        pad: NihilStyle.s(14)

        Item {
            id: head
            width: parent.width
            height: NihilStyle.s(40)
            DotText {
                id: title
                anchors.verticalCenter: parent.verticalCenter
                x: NihilStyle.s(6)
                text: Translation.tr("Clipboard").toUpperCase()
                dot: NihilStyle.s(3.2)
                spacing: NihilStyle.s(1.9)
                color: NihilStyle.ink
            }
            NText {
                anchors.left: title.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.verticalCenter: parent.verticalCenter
                figures: true
                text: root.rows.length
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            NConfirm {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                visible: Cliphist.entries.length > 0
                height: NihilStyle.s(34)
                glyph: "delete_sweep"
                label: Translation.tr("Clear")
                onConfirmed: Cliphist.wipe()
            }
        }

        NField {
            id: search
            y: head.height + NihilStyle.s(10)
            width: parent.width
            height: NihilStyle.s(44)
            glyph: "search"
            placeholder: Translation.tr("Search what you copied")
            clearable: true
            onEdited: text => { root.query = text; list.currentIndex = 0 }
            onStepped: by => list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + by))
            onEntered: root.use(root.rows[list.currentIndex])
        }

        ListView {
            id: list
            y: search.y + search.height + NihilStyle.s(10)
            width: parent.width
            height: parent.height - y
            clip: true
            spacing: NihilStyle.s(6)
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
            anchors.centerIn: list
            width: list.width - NihilStyle.s(40)
            visible: list.count === 0
            glyph: root.query.length > 0 ? "search_off" : "content_paste"
            title: root.query.length > 0 ? Translation.tr("Nothing matches") : Translation.tr("Nothing copied yet")
            line: root.query.length > 0 ? Translation.tr("Try another word") : Translation.tr("What you copy lands here")
        }
    }
}
