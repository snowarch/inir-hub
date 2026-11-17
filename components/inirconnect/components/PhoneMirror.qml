pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

ColumnLayout {
    id: root
    readonly property real d: IrisStyle.density
    spacing: Math.round(8 * root.d)
    implicitHeight: mirrorPlate.implicitHeight + navRow.implicitHeight + spacing

    IrisPlate {
        id: mirrorPlate
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumWidth: Math.round(180 * root.d)
        Layout.minimumHeight: Math.round(160 * root.d)
        implicitHeight: Math.round(180 * root.d)
        radius: IrisStyle.radiusCard
        color: IrisStyle.formPlate

        Rectangle {
            anchors.top: parent.top
            anchors.topMargin: Math.round(10 * root.d)
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.round(32 * root.d)
            height: Math.round(3.5 * root.d)
            radius: height / 2
            color: IrisStyle.hairline
        }

        Column {
            anchors.centerIn: parent
            width: parent.width - Math.round(24 * root.d)
            spacing: Math.round(10 * root.d)

            IrisSquircle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: Math.round(40 * root.d)
                height: width
                glyph: AndroidState.connected ? "phone_android" : "phonelink_off"
                tint: AndroidState.connected ? IrisStyle.accent : IrisStyle.identity.gray
            }

            Column {
                width: parent.width
                spacing: Math.round(2 * root.d)

                IrisText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: AndroidState.connected ? AndroidState.deviceName : Translation.tr("No device connected")
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeBody
                    font.weight: IrisStyle.weight(Font.Bold)
                }

                IrisText {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    text: {
                        if (AndroidState.hasAdb)
                            return AndroidState.selectedSerial
                        if (AndroidState.hasKde)
                            return AndroidState.deviceIp.length > 0 ? `KDE Connect • ${AndroidState.deviceIp}` : "KDE Connect activo"
                        return Translation.tr("Connect via USB or Wireless ADB")
                    }
                    color: IrisStyle.subtext
                    font.pixelSize: IrisStyle.typeCaption
                }
            }

            IrisButton {
                anchors.horizontalCenter: parent.horizontalCenter
                emphasized: AndroidState.connected
                selected: AndroidState.mirrorRunning
                enabled: AndroidState.connected
                opacity: AndroidState.connected ? 1.0 : 0.55
                text: {
                    if (AndroidState.mirrorRunning)
                        return Translation.tr("Stop mirror")
                    if (!AndroidState.hasAdb && AndroidState.hasKde)
                        return Translation.tr("Pair ADB for mirror")
                    return Translation.tr("Start mirror")
                }
                onClicked: AndroidState.openScrcpyWindow()
            }
        }
    }

    RowLayout {
        id: navRow
        Layout.fillWidth: true
        spacing: Math.round(6 * root.d)

        Repeater {
            model: [
                { icon: "arrow_back", key: "KEYCODE_BACK", label: "Back" },
                { icon: "radio_button_unchecked", key: "KEYCODE_HOME", label: "Home" },
                { icon: "crop_square", key: "KEYCODE_APP_SWITCH", label: "Recents" }
            ]

            delegate: IrisButton {
                id: navBtn
                required property var modelData
                Layout.fillWidth: true
                Layout.preferredWidth: 1
                implicitHeight: Math.round(32 * root.d)
                Accessible.name: Translation.tr(navBtn.modelData.label)
                onClicked: AndroidState.sendKeyEvent(navBtn.modelData.key)

                MaterialSymbol {
                    anchors.centerIn: parent
                    text: navBtn.modelData.icon
                    iconSize: Math.round(16 * root.d)
                    color: navBtn.foreground
                }
            }
        }
    }
}
