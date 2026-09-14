pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root
    focus: true

    readonly property bool usePasswordChars: !(PolkitService.flow?.responseVisible ?? false)

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

    IrisSurface {
        id: card
        anchors.centerIn: parent
        width: Math.min(440, parent.width - 40)
        implicitHeight: body.implicitHeight + IrisStyle.spaceLarge * 2
        raised: true

        ColumnLayout {
            id: body
            anchors.fill: parent
            anchors.margins: IrisStyle.spaceLarge
            spacing: IrisStyle.spaceMedium

            Item {
                Layout.fillWidth: true
                Layout.preferredHeight: IrisStyle.headerHeight

                IrisSectionHeader {
                    id: authHeader
                    anchors.fill: parent
                    icon: "admin_panel_settings"
                    eyebrow: "IRIS / AUTH"
                    title: Translation.tr("Authentication")
                    subtitle: PolkitService.actionLabel !== Translation.tr("Authentication")
                        ? PolkitService.actionLabel : Translation.tr("Privileged action")
                    indexText: "AUTH"
                }
            }

            IrisText {
                Layout.fillWidth: true
                text: PolkitService.cleanMessage
                role: IrisText.Body
                wrapMode: Text.WordWrap
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 8 * IrisStyle.density

                Rectangle {
                    Layout.preferredWidth: 3 * IrisStyle.density
                    Layout.preferredHeight: 34 * IrisStyle.density
                    radius: width / 2
                    color: IrisStyle.accent
                }

                IrisField {
                    id: input
                    Layout.fillWidth: true
                    implicitHeight: 48 * IrisStyle.density
                    focus: true
                    enabled: PolkitService.interactionAvailable
                    echoMode: root.usePasswordChars ? TextInput.Password : TextInput.Normal
                    placeholderText: PolkitService.cleanPrompt
                    onAccepted: root.submit()
                }
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: IrisStyle.spaceSmall
                Item { Layout.fillWidth: true }
                IrisKey { key: "ESC" }
                IrisButton {
                    text: Translation.tr("Cancel")
                    quiet: true
                    onClicked: PolkitService.cancel()
                }
                IrisButton {
                    text: Translation.tr("Authenticate")
                    emphasized: true
                    enabled: PolkitService.interactionAvailable
                    onClicked: root.submit()
                }
            }
        }
    }
}
