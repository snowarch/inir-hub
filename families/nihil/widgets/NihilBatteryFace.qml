import QtQuick
import qs.services
import qs.modules.nihil.style

// The charge as a figure over its line. The line turns to the error colour only when the battery is low and not charging.
NihilWidgetFace {
    id: root

    readonly property int charge: Math.round(Battery.percentage * 100)
    readonly property bool warned: Battery.isLowAndNotCharging
    readonly property color tint: root.warned ? NihilStyle.danger : root.accent
    readonly property string saying: String(root.widget.timeLabel ?? "").length > 0 ? root.widget.timeLabel
        : Battery.isCharging ? Translation.tr("Charging")
        : Battery.isFull ? Translation.tr("Fully charged") : Translation.tr("On battery")

    FaceBlank {
        visible: !Battery.available
        face: root
        glyph: "power"
        title: Translation.tr("On power")
        detail: Translation.tr("This computer has no battery")
    }

    Item {
        anchors.fill: parent
        visible: Battery.available

        NIcon {
            anchors.right: parent.right
            anchors.top: parent.top
            text: Battery.isCharging ? "bolt" : "battery"
            size: root.dp(22)
            color: Battery.isCharging ? root.accent : root.inkSoft
        }

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            spacing: root.dp(4)

            Row {
                spacing: root.dp(2)

                NText {
                    id: figure
                    figures: true
                    text: root.charge
                    font.weight: Font.Light
                    font.pixelSize: Math.min(root.contentHeight * 0.56, root.contentWidth * 0.42)
                    color: root.warned ? root.tint : root.ink
                }
                NText {
                    anchors.baseline: figure.baseline
                    text: "%"
                    font.pixelSize: figure.font.pixelSize * 0.36
                    color: root.inkSoft
                }
            }
            NText {
                width: parent.width
                text: root.saying
                elide: Text.ElideRight
                font.pixelSize: root.dp(13)
                color: root.inkSoft
            }
            FaceBar {
                ink: root.ink
                width: parent.width
                level: Battery.percentage
                tint: root.tint
            }
        }
    }
}
