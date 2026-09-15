pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    focus: true

    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)
    readonly property real d: IrisStyle.density

    function submit(): void {
        if (!PolkitService.interactionAvailable)
            return
        PolkitService.submit(input.text)
    }

    Keys.onPressed: event => {
        if (event.key === Qt.Key_Escape) {
            PolkitService.cancel()
            event.accepted = true
        }
    }

    Connections {
        target: PolkitService
        function onInteractionAvailableChanged(): void {
            if (!PolkitService.interactionAvailable)
                return
            input.text = ""
            input.forceActiveFocus()
        }
    }

    Rectangle {
        anchors.fill: parent
        color: IrisStyle.scrim
    }

    // A centred alert, like Close Confirm: what asks, why, the secret, two
    // equal answers. The accent marks the one thing that grants access.
    IrisSurface {
        id: card
        anchors.centerIn: parent
        width: Math.min(320 * root.d, parent.width - 40)
        implicitHeight: body.implicitHeight + 40 * root.d
        radius: Math.round(22 * root.d)
        raised: true

        ColumnLayout {
            id: body
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            anchors.leftMargin: 20 * root.d
            anchors.rightMargin: 20 * root.d
            spacing: 0

            Rectangle {
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: Math.round(52 * root.d)
                implicitHeight: implicitWidth
                radius: width / 2
                color: ColorUtils.applyAlpha(IrisStyle.accent, 0.18)
                MaterialSymbol {
                    anchors.centerIn: parent
                    text: PolkitService.batteryChargeLimitRequest ? "battery_charging_full" : "lock"
                    fill: 1
                    iconSize: Math.round(26 * root.d)
                    color: IrisStyle.accent
                }
            }
            IrisText {
                Layout.fillWidth: true
                Layout.topMargin: 14 * root.d
                horizontalAlignment: Text.AlignHCenter
                text: PolkitService.actionLabel !== Translation.tr("Authentication")
                    ? PolkitService.actionLabel : Translation.tr("Authentication required")
                font.pixelSize: 15 * IrisStyle.typeScale
                font.weight: Font.DemiBold
                wrapMode: Text.Wrap
            }
            IrisText {
                Layout.fillWidth: true
                Layout.topMargin: 6 * root.d
                visible: text.length > 0
                horizontalAlignment: Text.AlignHCenter
                text: PolkitService.cleanMessage
                color: IrisStyle.subtext
                font.pixelSize: 12 * IrisStyle.typeScale
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            IrisField {
                id: input
                Layout.fillWidth: true
                Layout.topMargin: 16 * root.d
                implicitHeight: Math.round(40 * root.d)
                focus: true
                enabled: PolkitService.interactionAvailable
                echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                placeholderText: PolkitService.cleanPrompt
                font.pixelSize: 14 * IrisStyle.typeScale
                onAccepted: root.submit()
                background: Rectangle {
                    radius: height / 2
                    color: ColorUtils.applyAlpha(IrisStyle.text, input.activeFocus ? 0.12 : 0.08)
                    border.width: input.activeFocus ? Math.max(1, Math.round(1.5 * root.d)) : 0
                    border.color: ColorUtils.applyAlpha(IrisStyle.accent, 0.8)
                    Behavior on color { ColorAnimation { duration: IrisStyle.duration(120) } }
                }
            }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 14 * root.d
                spacing: 8 * root.d
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    colBackground: ColorUtils.applyAlpha(IrisStyle.text, 0.12)
                    colBackgroundHover: ColorUtils.applyAlpha(IrisStyle.text, 0.2)
                    text: Translation.tr("Cancel")
                    onClicked: PolkitService.cancel()
                }
                IrisButton {
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    emphasized: true
                    enabled: PolkitService.interactionAvailable
                    text: Translation.tr("Authenticate")
                    onClicked: root.submit()
                }
            }
        }
    }
}
