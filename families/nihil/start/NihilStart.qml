pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style
import qs.modules.nihil.state

// Start (the shell's search key): one block over the middle of the bar. The search line leads on paper with the apps
// under it; beside them what plays, the machine's readings, the home folders and the power keys. Typing filters the
// apps, the arrows walk them, Enter opens the one marked.
NPopup {
    id: root

    open: NihilState.startOpen
    namespace: "nihil:start"
    onDismissed: root.done()
    onOpenChanged: {
        if (!root.open) return
        field.text = ""
        apps.at = 0
        field.forceActiveFocus()
        ResourceUsage.ensureRunning()
    }

    function done(): void { GlobalStates.searchOpen = false }

    NRack {
        id: rack
        width: NihilStyle.s(768)
        height: side.implicitHeight
        x: Math.round((parent.width - width) / 2)
        y: root.barBottom ? parent.height - height - root.edgeBottom : root.edgeTop

        NTile {
            id: search
            width: apps.width
            height: NihilStyle.s(76)
            paper: true
            interactive: true
            onClicked: field.forceActiveFocus()

            NIcon {
                id: lens
                x: search.pad
                anchors.verticalCenter: parent.verticalCenter
                text: "search"
                size: NihilStyle.s(26)
                weight: 2.4
                color: search.ink
            }
            TextInput {
                id: field
                anchors.left: lens.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.right: parent.right
                anchors.rightMargin: search.pad
                anchors.verticalCenter: parent.verticalCenter
                font.family: NihilStyle.grotesk
                font.pixelSize: NihilStyle.s(26)
                font.weight: Font.Bold
                font.letterSpacing: -NihilStyle.s(1) * 0.5
                color: search.ink
                selectionColor: NihilStyle.accent
                selectedTextColor: NihilStyle.onAccent
                selectByMouse: true
                clip: true
                onTextChanged: apps.at = 0
                Keys.onReturnPressed: apps.launch(apps.marked)
                Keys.onEnterPressed: apps.launch(apps.marked)
                Keys.onEscapePressed: root.done()
                Keys.onUpPressed: apps.walk(-1)
                Keys.onDownPressed: apps.walk(1)
                NText {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: field.text.length === 0
                    text: Translation.tr("Search")
                    font: field.font
                    color: Qt.alpha(search.ink, 0.42)
                }
            }
        }

        StartApps {
            id: apps
            y: search.height + NihilStyle.seam
            width: NihilStyle.s(404)
            height: rack.height - y
            query: field.text
            onLaunched: root.done()
        }

        StartSide {
            id: side
            x: apps.width + NihilStyle.seam
            width: rack.width - x
            onDone: root.done()
        }
    }
}
