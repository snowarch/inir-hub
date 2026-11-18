pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.nihil.style

// The battery as a field of dots on a piece: the charge, what it is doing and the time left over it, the charge as
// dots lit from the left (grey while it drains, the signal colour while it charges or runs low).
NihilFace {
    id: root

    readonly property real level: Battery.available ? Battery.percentage : 0
    readonly property bool charging: Battery.isCharging
    readonly property string state: !Battery.available ? Translation.tr("No battery")
        : root.charging ? Translation.tr("Charging") : Battery.isPluggedIn ? Translation.tr("Plugged in")
        : Translation.tr("Discharging")
    readonly property real secondsLeft: root.charging ? (Battery.timeToFull ?? 0) : (Battery.timeToEmpty ?? 0)
    readonly property string timeLeft: root.secondsLeft > 0
        ? `${Math.floor(root.secondsLeft / 3600)}:${String(Math.floor(root.secondsLeft % 3600 / 60)).padStart(2, "0")}` : ""

    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: NihilStyle.piece

        Item {
            id: head
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: root.dp(16) }
            height: root.dp(22)
            NText {
                anchors.left: parent.left
                figures: true
                font.pixelSize: root.dp(15)
                text: `${Math.round(root.level * 100)}%`
                color: Battery.isLow && !root.charging ? NihilStyle.accent : NihilStyle.ink
            }
            NText {
                visible: !root.small
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                font.pixelSize: root.dp(14)
                text: root.state
            }
            NText {
                anchors.right: parent.right
                figures: true
                font.pixelSize: root.dp(15)
                text: root.small ? "" : root.timeLeft
            }
            NIcon {
                visible: root.small && root.charging
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: "bolt"
                size: root.dp(18)
                color: NihilStyle.accent
            }
        }
        DotGrid {
            anchors { left: parent.left; right: parent.right; top: head.bottom; bottom: parent.bottom }
            anchors.margins: root.dp(12)
            anchors.topMargin: root.dp(8)
            columns: root.small ? 5 : 11
            rows: root.large ? 9 : 4
            columnFirst: true
            level: root.level
            litColor: root.charging || Battery.isLow ? NihilStyle.accent : NihilStyle.inkSoft
            offColor: NihilStyle.pieceRaised
        }
    }
}
