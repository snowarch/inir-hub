pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// Start (the shell's search key): one piece over the middle of the bar. The apps on the left; on the right the search
// field, the home folders, storage and memory, what plays, the weather, the battery and the power keys. Typing
// filters the apps; Enter opens the first.
NPopup {
    id: root

    open: NihilState.startOpen
    namespace: "nihil:start"
    onDismissed: GlobalStates.searchOpen = false
    onOpenChanged: {
        if (!root.open) return
        field.text = ""
        field.forceActiveFocus()
        ResourceUsage.ensureRunning()
    }

    readonly property real g: NihilStyle.cellGap

    function done(): void { GlobalStates.searchOpen = false }

    NCard {
        id: card
        width: NihilStyle.cells(4) * 2 + root.g + NihilStyle.panelPad * 2
        height: side.y + side.height + NihilStyle.panelPad * 2
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        StartApps {
            id: apps
            width: NihilStyle.cells(4)
            height: parent.height
            query: field.text
            onLaunched: root.done()
        }

        NButton {
            id: search
            x: NihilStyle.cells(4) + root.g
            width: NihilStyle.cells(4)
            height: NihilStyle.cell
            tone: NihilStyle.pieceRaised
            onClicked: field.forceActiveFocus()
            NButton {
                id: lens
                x: NihilStyle.s(6)
                anchors.verticalCenter: parent.verticalCenter
                width: parent.height - NihilStyle.s(12); height: width
                icon: "search"
            }
            TextInput {
                id: field
                anchors.left: lens.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.right: parent.right
                anchors.rightMargin: NihilStyle.s(16)
                anchors.verticalCenter: parent.verticalCenter
                font.family: NihilStyle.mono
                font.pixelSize: NihilStyle.textBody
                color: NihilStyle.ink
                selectionColor: NihilStyle.accent
                selectedTextColor: NihilStyle.onAccent
                clip: true
                Keys.onReturnPressed: apps.launch(apps.first)
                Keys.onEnterPressed: apps.launch(apps.first)
                Keys.onEscapePressed: root.done()
                NText {
                    anchors.fill: parent
                    visible: field.text.length === 0
                    mono: true
                    text: Translation.tr("Search this PC").toUpperCase()
                    color: NihilStyle.inkSoft
                }
            }
        }

        StartSide {
            id: side
            x: search.x
            y: search.height + root.g
            w: NihilStyle.cells(4)
            live: root.open
            onDone: root.done()
        }
    }
}
