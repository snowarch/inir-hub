pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs
import qs.services
import qs.services.deferred
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// What was copied, on the slab: the pins first, then the history newest first. The search keeps the keys: the arrows walk
// the rows, Enter copies the marked one and closes.
Item {
    id: root

    property var screen: null
    property bool flipped: false
    property real room: 0
    property bool open: false

    implicitWidth: NihilStyle.s(560)
    implicitHeight: Math.min(NihilStyle.s(620), root.room)

    property string query: ""
    property bool armed: false

    readonly property var pins: {
        const words = root.query.trim().toLowerCase()
        return (Cliphist.pinned ?? [])
            .filter(text => words.length === 0 || String(text).toLowerCase().includes(words))
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
        if (!root.open)
            return
        root.query = ""
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

        NField {
            id: search
            width: sheet.width - wipe.width - NihilStyle.gap
            height: NihilStyle.s(48)
            radius: NihilStyle.rCard
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

        NButton {
            id: wipe
            anchors.right: parent.right
            anchors.verticalCenter: search.verticalCenter
            visible: Cliphist.entries.length > 0
            icon: "delete_sweep"
            label: root.armed ? Translation.tr("Clear all") : ""
            lit: root.armed
            onClicked: {
                if (!root.armed) {
                    root.armed = true
                    return
                }
                root.armed = false
                Cliphist.wipe()
            }
        }

        ListView {
            id: list
            y: search.y + search.height + NihilStyle.s(12)
            width: sheet.width
            height: sheet.height - y
            clip: true
            spacing: NihilStyle.s(4)
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
                onHoveredChanged: if (clip.hovered) list.currentIndex = clip.index
            }
        }

        Column {
            anchors.centerIn: list
            visible: list.count === 0
            spacing: NihilStyle.s(6)

            NIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? "search_off" : "clipboard"
                size: NihilStyle.s(32)
                color: NihilStyle.inkSoft
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? Translation.tr("Nothing matches") : Translation.tr("Nothing copied yet")
                font.pixelSize: NihilStyle.textLarge
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: root.query.length > 0 ? Translation.tr("Try another word") : Translation.tr("What you copy lands here")
                color: NihilStyle.inkSoft
            }
        }
    }
}
