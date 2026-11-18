pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The clock: the hour in dots, straight on the wallpaper. Hours in the signal colour and minutes in ink (two-tone),
// side by side when it is wide, hours over minutes when it is square. A small clock is a round piece: the time in
// figures and the day under it.
NihilFace {
    id: root

    readonly property var options: Config.options?.nihil?.clock ?? ({})
    readonly property bool fused: (root.options.style ?? "dots") === "fused"
    readonly property bool twoTone: root.options.twoTone ?? true
    readonly property string hours: DateTime.time.split(":")[0] ?? "00"
    readonly property string minutes: (DateTime.time.split(":")[1] ?? "00").slice(0, 2)
    readonly property bool stacked: root.large
    // Columns: two digits each (5 + 1 + 5), a gap of two between the pairs; seven rows, or fifteen stacked.
    readonly property real pitch: root.stacked ? Math.min(root.width / 11, root.height / 15.2)
        : Math.min(root.width / 24, root.height / 7)

    Row {
        visible: !root.small
        anchors.centerIn: parent
        spacing: root.stacked ? 0 : root.pitch * 2 - figureH.spacing
        Column {
            spacing: root.pitch * 1.2
            DotText {
                id: figureH
                text: root.hours
                dot: root.pitch * (root.fused ? 0.92 : 0.8)
                spacing: root.pitch - dot
                fuse: root.fused
                color: root.twoTone ? NihilStyle.accent : root.bareInk
            }
            DotText {
                visible: root.stacked
                text: root.minutes
                dot: figureH.dot
                spacing: figureH.spacing
                fuse: root.fused
                color: root.bareInk
            }
        }
        DotText {
            visible: !root.stacked
            text: root.minutes
            dot: figureH.dot
            spacing: figureH.spacing
            fuse: root.fused
            color: root.bareInk
        }
    }

    // Small: a round piece with the time and the day.
    Rectangle {
        visible: root.small
        anchors.centerIn: parent
        width: Math.min(parent.width, parent.height)
        height: width
        radius: width / 2
        color: NihilStyle.piece
        Column {
            anchors.centerIn: parent
            spacing: root.dp(4)
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                font.bold: true
                font.pixelSize: root.dp(40)
                text: DateTime.time
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                figures: true
                color: NihilStyle.inkSoft
                font.pixelSize: root.dp(12)
                font.capitalization: Font.AllUppercase
                text: Translation.locale.toString(DateTime.clock.date, "dddd")
            }
        }
    }
}
