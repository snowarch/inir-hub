pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style

ColumnLayout {
    id: root

    readonly property real d: IrisStyle.density
    readonly property var networks: (Network.wifiNetworks ?? []).slice()
        .sort((a, b) => (b.active ? 1 : 0) - (a.active ? 1 : 0) || b.strength - a.strength)
        .slice(0, 8)
    spacing: 2 * root.d

    Component.onCompleted: if (Network.wifiEnabled) Network.rescanWifi()

    IrisText {
        visible: !Network.wifiEnabled || root.networks.length === 0
        Layout.fillWidth: true
        Layout.margins: 10 * root.d
        text: !Network.wifiEnabled ? Translation.tr("Wi-Fi is off")
            : Network.wifiScanning ? Translation.tr("Looking for networks…")
            : Translation.tr("No networks in range")
        role: IrisText.Meta
    }

    Repeater {
        model: Network.wifiEnabled ? root.networks : []
        ColumnLayout {
            id: networkEntry
            required property var modelData
            Layout.fillWidth: true
            spacing: 4 * root.d
            // NetworkManager asks for the key when a secured network has none saved yet: the row opens a field for it.
            readonly property bool asking: networkEntry.modelData.askingPassword ?? false

            IrisButton {
                id: networkRow
                Layout.fillWidth: true
                quiet: true
                implicitHeight: Math.round(40 * root.d)
                buttonRadius: IrisStyle.radiusTile
                onClicked: {
                    if (networkEntry.modelData.active) Network.disconnectWifiNetwork()
                    else Network.connectToWifiNetwork(networkEntry.modelData)
                }
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10 * root.d
                    anchors.rightMargin: 10 * root.d
                    spacing: 10 * root.d
                    MaterialSymbol {
                        text: networkEntry.modelData.strength >= 75 ? "signal_wifi_4_bar"
                            : networkEntry.modelData.strength >= 50 ? "network_wifi_3_bar"
                            : networkEntry.modelData.strength >= 25 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                        iconSize: Math.round(19 * root.d)
                        color: networkEntry.modelData.active ? IrisStyle.accent : IrisStyle.text
                    }
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: -2
                        IrisText {
                            Layout.fillWidth: true
                            text: networkEntry.modelData.ssid
                            elide: Text.ElideRight
                            color: networkEntry.modelData.active ? IrisStyle.accent : IrisStyle.text
                        }
                        IrisText {
                            Layout.fillWidth: true
                            visible: networkEntry.modelData.active
                            text: Translation.tr("Connected")
                            role: IrisText.Meta
                        }
                    }
                    MaterialSymbol {
                        visible: networkEntry.modelData.isSecure
                        text: "lock"
                        iconSize: Math.round(13 * root.d)
                        color: IrisStyle.textTertiary
                    }
                }
            }

            RowLayout {
                visible: networkEntry.asking
                Layout.fillWidth: true
                Layout.leftMargin: 10 * root.d
                Layout.rightMargin: 4 * root.d
                Layout.bottomMargin: 4 * root.d
                spacing: 6 * root.d
                function submit(): void {
                    if (password.text.length === 0) return
                    Network.changePassword(networkEntry.modelData, password.text)
                    password.text = ""
                }
                IrisField {
                    id: password
                    Layout.fillWidth: true
                    implicitHeight: Math.round(34 * root.d)
                    echoMode: TextInput.Password
                    placeholderText: Translation.tr("Password")
                    font.pixelSize: IrisStyle.typeBody
                    onAccepted: parent.submit()
                    Keys.onEscapePressed: networkEntry.modelData.askingPassword = false
                    background: Rectangle {
                        radius: height / 2
                        color: password.activeFocus ? IrisStyle.fill : IrisStyle.fillQuiet
                        border.width: password.activeFocus ? Math.max(1, Math.round(1.5 * root.d)) : 0
                        border.color: IrisStyle.tintBorder(IrisStyle.accent)
                    }
                }
                IrisButton {
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    colBackground: IrisStyle.fill
                    colBackgroundHover: IrisStyle.fillHover
                    text: Translation.tr("Cancel")
                    onClicked: networkEntry.modelData.askingPassword = false
                }
                IrisButton {
                    implicitHeight: Math.round(34 * root.d)
                    buttonRadius: height / 2
                    buttonRadiusPressed: height / 2
                    emphasized: true
                    text: Translation.tr("Connect")
                    onClicked: parent.submit()
                }
            }
            // The field takes the keys the moment it appears, so the key can be typed at once.
            Timer {
                id: focusLater
                interval: 0
                onTriggered: password.forceActiveFocus()
            }
            onAskingChanged: if (networkEntry.asking) focusLater.restart()
        }
    }
}
