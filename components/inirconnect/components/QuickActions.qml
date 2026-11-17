pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    spacing: Math.round(6 * root.d)
    implicitHeight: titleText.implicitHeight + grid.implicitHeight + spacing

    IrisText {
        id: titleText
        text: Translation.tr("QUICK ACTIONS")
        color: IrisStyle.subtext
        font.family: IrisStyle.fontLabel
        font.pixelSize: Math.max(9, Math.round(10 * root.d))
        font.weight: IrisStyle.weight(Font.Bold)
        font.letterSpacing: 0.8
    }

    GridLayout {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        columns: 2
        rowSpacing: Math.round(6 * root.d)
        columnSpacing: Math.round(6 * root.d)

        Repeater {
            model: [
                { icon: "notifications", label: Translation.tr("Notifications"), active: AndroidState.notificationsOpen, act: () => AndroidState.toggleSheet("notifications") },
                { icon: "send_to_mobile", label: Translation.tr("Send alert"), active: false, act: () => AndroidState.pingDevice() },
                { icon: "upload_file", label: Translation.tr("Send file"), active: AndroidState.shareOpen, act: () => AndroidState.shareFile() },
                { icon: "folder_open", label: Translation.tr("Browse files"), active: false, act: () => AndroidState.browseFiles() },
                { icon: "notifications_active", label: Translation.tr("Ring phone"), active: false, act: () => AndroidState.findPhone() },
                { icon: "content_paste_go", label: Translation.tr("Clipboard"), active: false, act: () => AndroidState.sendClipboard() },
                { icon: "screenshot", label: Translation.tr("Screenshot"), active: false, act: () => AndroidState.takeScreenshot() },
                { icon: "fiber_manual_record", label: AndroidState.recording ? Translation.tr("Stop") : Translation.tr("Record screen"), active: AndroidState.recording, act: () => AndroidState.toggleRecording() },
                { icon: "visibility", label: Translation.tr("Keep awake"), active: AndroidState.keepAwake, act: () => AndroidState.toggleKeepAwake() },
                { icon: "visibility_off", label: Translation.tr("Screen off"), active: false, act: () => AndroidState.turnScreenOff() }
            ]

            delegate: Item {
                id: tile
                required property var modelData
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.preferredWidth: 1
                Layout.minimumHeight: Math.round(35 * root.d)
                implicitHeight: Math.round(38 * root.d)

                property real lit: tile.modelData.active ? 1 : 0
                Behavior on lit { NumberAnimation { duration: IrisStyle.revealDuration; easing.type: Easing.OutCubic } }

                readonly property color fg: ColorUtils.mix(IrisStyle.inkOnAccentFill, IrisStyle.text, tile.lit)

                IrisPlate {
                    anchors.fill: parent
                    radius: IrisStyle.radiusTile
                    lit: tile.modelData.active
                    color: ColorUtils.mix(
                        IrisStyle.accentFill,
                        tileMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.formPlate,
                        tile.lit
                    )
                    scale: tileMouse.pressed ? IrisStyle.pressScale(0.97) : 1.0
                    Behavior on scale { NumberAnimation { duration: IrisStyle.feedbackDuration; easing.type: IrisStyle.feedbackEasing } }
                    Behavior on color { ColorAnimation { duration: IrisStyle.feedbackDuration } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Math.round(10 * root.d)
                        anchors.rightMargin: Math.round(10 * root.d)
                        spacing: Math.round(6 * root.d)

                        MaterialSymbol {
                            text: tile.modelData.icon
                            iconSize: Math.round(15 * root.d)
                            fill: tile.modelData.active ? 1 : 0
                            color: tile.fg
                        }

                        IrisText {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: tile.modelData.label
                            color: tile.fg
                            font.pixelSize: IrisStyle.typeCaption
                            font.weight: IrisStyle.weight(Font.Medium)
                        }
                    }
                }

                MouseArea {
                    id: tileMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: tile.modelData.act()
                }
            }
        }
    }
}
