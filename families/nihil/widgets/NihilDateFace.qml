pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The date on a round piece: the month in small figures, the day in big dots, the weekday in the serif under it in
// the signal colour. Wider sizes keep the circle and let the year sit under the day.
NihilFace {
    id: root

    readonly property date now: DateTime.clock.date
    readonly property real diameter: Math.min(root.width, root.height)

    Rectangle {
        anchors.centerIn: parent
        width: root.diameter
        height: width
        radius: width / 2
        color: NihilStyle.piece

        Column {
            anchors.centerIn: parent
            spacing: root.diameter * 0.04
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                mono: true
                font.pixelSize: Math.round(root.diameter * 0.075)
                font.capitalization: Font.AllUppercase
                color: NihilStyle.inkSoft
                text: Translation.locale.toString(root.now, "MMM")
            }
            DotText {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Translation.locale.toString(root.now, "dd")
                dot: root.diameter * 0.045
                spacing: dot * 0.3
                fuse: (Config.options?.nihil?.clock?.style ?? "dots") === "fused"
            }
            NText {
                anchors.horizontalCenter: parent.horizontalCenter
                serif: true
                font.pixelSize: Math.round(root.diameter * 0.1)
                font.weight: Font.DemiBold
                font.capitalization: Font.AllUppercase
                color: NihilStyle.accent
                text: Translation.locale.toString(root.now, "dddd")
            }
        }
    }
}
