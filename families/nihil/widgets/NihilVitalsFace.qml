pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.nihil.style

// The machine at a glance. Small: memory as a field of dots under its share. Medium: memory and the disk as two pies
// on a pill, their shares between them. Large: both, the dots over the pies.
NihilFace {
    id: root

    readonly property real memory: ResourceUsage.memoryUsedPercentage ?? 0
    readonly property real disk: ResourceUsage.diskUsedPercentage ?? 0

    component MemoryCard: Rectangle {
        radius: root.radius
        color: NihilStyle.piece
        NText {
            id: share
            x: root.dp(16); y: root.dp(14)
            figures: true
            font.pixelSize: root.dp(20)
            color: NihilStyle.accent
            text: `${Math.round(root.memory * 100)}%`
        }
        NText {
            x: share.x
            anchors.top: share.bottom
            figures: true
            font.pixelSize: root.dp(14)
            text: Translation.tr("RAM")
        }
        NIcon {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: root.dp(16)
            text: "memory"
            size: root.dp(22)
        }
        DotGrid {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: root.dp(14) }
            height: parent.height * 0.48
            columns: 7
            rows: 4
            level: root.memory
            columnFirst: true
            offColor: NihilStyle.pieceRaised
        }
    }

    component Pies: Rectangle {
        radius: height / 2
        color: NihilStyle.piece
        Row {
            anchors.centerIn: parent
            spacing: -root.dp(14)
            PieDial {
                width: root.dp(76); height: width
                value: root.memory
                offColor: NihilStyle.pieceRaised
            }
            Rectangle {
                z: 1
                anchors.verticalCenter: parent.verticalCenter
                width: root.dp(64); height: width; radius: width / 2
                color: NihilStyle.well
                Column {
                    anchors.centerIn: parent
                    NText { anchors.horizontalCenter: parent.horizontalCenter; figures: true; font.pixelSize: root.dp(11); text: `${Translation.tr("RAM")} ${Math.round(root.memory * 100)}` }
                    NText { anchors.horizontalCenter: parent.horizontalCenter; figures: true; font.pixelSize: root.dp(11); text: `${Translation.tr("DISK")} ${Math.round(root.disk * 100)}`; color: NihilStyle.inkSoft }
                }
            }
            PieDial {
                width: root.dp(76); height: width
                value: root.disk
                offColor: NihilStyle.pieceRaised
            }
        }
    }

    MemoryCard {
        visible: root.small
        anchors.fill: parent
    }
    Pies {
        visible: root.medium
        anchors.centerIn: parent
        width: Math.min(parent.width, root.dp(300))
        height: Math.min(parent.height, root.dp(120))
    }
    Column {
        visible: root.large
        anchors.fill: parent
        spacing: root.dp(14)
        MemoryCard { width: parent.width; height: parent.height - pies.height - parent.spacing }
        Pies { id: pies; width: parent.width; height: root.dp(120) }
    }
}
