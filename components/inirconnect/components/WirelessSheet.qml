pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components
import "../state"

Item {
    id: root
    readonly property real d: IrisStyle.density
    readonly property bool shown: AndroidState.wirelessOpen
    property string activeTab: "qr" // "qr", "manual", "usb"

    Layout.fillWidth: true
    implicitHeight: root.shown ? sheetPlate.implicitHeight : 0
    opacity: root.shown ? 1.0 : 0.0
    visible: implicitHeight > 0
    clip: true

    Behavior on implicitHeight {
        NumberAnimation {
            duration: IrisStyle.morphDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: IrisStyle.morphCurve
        }
    }
    Behavior on opacity {
        NumberAnimation {
            duration: IrisStyle.revealDuration
            easing.type: Easing.OutCubic
        }
    }

    IrisPlate {
        id: sheetPlate
        width: parent.width
        height: root.implicitHeight
        implicitHeight: col.implicitHeight + Math.round(24 * root.d)
        radius: IrisStyle.radiusCard
        color: IrisStyle.fill
        clip: true

        ColumnLayout {
            id: col
            width: parent.width - Math.round(24 * root.d)
            x: Math.round(12 * root.d)
            y: Math.round(12 * root.d)
            spacing: Math.round(10 * root.d)

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(8 * root.d)

                IrisSquircle {
                    width: Math.round(28 * root.d)
                    height: width
                    glyph: "wifi_tethering"
                    tint: IrisStyle.accent
                }

                IrisText {
                    Layout.fillWidth: true
                    text: Translation.tr("Wireless Debugging (ADB)")
                    color: IrisStyle.text
                    font.family: IrisStyle.fontTitle
                    font.pixelSize: IrisStyle.typeLabel
                    font.weight: IrisStyle.weight(Font.Bold)
                }

                IrisIconButton {
                    implicitWidth: Math.round(26 * root.d)
                    implicitHeight: Math.round(26 * root.d)
                    iconSize: Math.round(16 * root.d)
                    materialIcon: "close"
                    onClicked: AndroidState.toggleSheet("wireless")
                }
            }

            // Tabs Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.d)

                Repeater {
                    model: [
                        { id: "qr", label: Translation.tr("QR Code"), icon: "qr_code_scanner" },
                        { id: "manual", label: Translation.tr("Pairing code"), icon: "password" },
                        { id: "usb", label: Translation.tr("USB to Wi-Fi"), icon: "usb" }
                    ]

                    delegate: IrisPlate {
                        id: tabBtn
                        required property var modelData
                        Layout.fillWidth: true
                        Layout.preferredHeight: Math.round(30 * root.d)
                        radius: IrisStyle.radiusTile
                        lit: root.activeTab === modelData.id
                        color: lit ? IrisStyle.accentFill : (tabMouse.containsMouse ? IrisStyle.fillHover : IrisStyle.formPlate)

                        RowLayout {
                            anchors.centerIn: parent
                            spacing: Math.round(5 * root.d)

                            IrisSquircle {
                                width: Math.round(16 * root.d)
                                height: width
                                glyph: tabBtn.modelData.icon
                                tint: tabBtn.lit ? IrisStyle.inkOnAccentFill : IrisStyle.subtext
                            }

                            IrisText {
                                text: tabBtn.modelData.label
                                color: tabBtn.lit ? IrisStyle.inkOnAccentFill : IrisStyle.text
                                font.pixelSize: Math.round(11 * root.d)
                                font.weight: tabBtn.lit ? IrisStyle.weight(Font.Bold) : IrisStyle.weight(Font.Normal)
                            }
                        }

                        MouseArea {
                            id: tabMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: root.activeTab = tabBtn.modelData.id
                        }
                    }
                }
            }

            // TAB 1: QR CODE PAIRING
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.activeTab === "qr"
                spacing: Math.round(8 * root.d)

                // QR Image card
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: Math.round(156 * root.d)
                    height: width
                    radius: Math.round(12 * root.d)
                    color: "#FFFFFF" // literal: QR scanner requires high-contrast white backdrop
                    border.width: 1
                    border.color: IrisStyle.hairline

                    Image {
                        anchors.centerIn: parent
                        width: parent.width - Math.round(12 * root.d)
                        height: width
                        fillMode: Image.PreserveAspectFit
                        cache: false
                        source: AndroidState.qrImagePath.length > 0 ? `file://${AndroidState.qrImagePath}?t=${AndroidState.qrUpdated}` : ""
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: parent.radius
                        color: "#CCFFFFFF" // literal: white semi-transparent scrim over QR box
                        visible: AndroidState.qrStatus === "starting"

                        Column {
                            anchors.centerIn: parent
                            spacing: Math.round(6 * root.d)
                            IrisSquircle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                width: Math.round(24 * root.d)
                                height: width
                                glyph: "sync"
                                tint: IrisStyle.accent
                            }
                            IrisText {
                                text: Translation.tr("Generating...")
                                color: "#221F1B" // literal: dark text over high-contrast white scrim
                                font.pixelSize: Math.round(10 * root.d)
                            }
                        }
                    }
                }

                // Instructions & Status
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(4 * root.d)

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Math.round(6 * root.d)

                        IrisSquircle {
                            width: Math.round(18 * root.d)
                            height: width
                            glyph: {
                                if (AndroidState.qrStatus === "connected") return "check_circle"
                                if (AndroidState.qrStatus === "pairing" || AndroidState.qrStatus === "connecting") return "sync"
                                if (AndroidState.qrStatus === "error" || AndroidState.qrStatus === "timeout") return "error"
                                return "qr_code_scanner"
                            }
                            tint: {
                                if (AndroidState.qrStatus === "connected") return IrisStyle.identity.green
                                if (AndroidState.qrStatus === "error" || AndroidState.qrStatus === "timeout") return IrisStyle.identity.red
                                return IrisStyle.accent
                            }
                        }

                        IrisText {
                            text: {
                                if (AndroidState.qrStatus === "connected") return Translation.tr("Device paired and connected!")
                                if (AndroidState.qrStatus === "pairing") return Translation.tr("Device detected. Pairing...")
                                if (AndroidState.qrStatus === "connecting") return Translation.tr("Connecting to ADB port...")
                                if (AndroidState.qrStatus === "timeout") return Translation.tr("Timed out. Press regenerate.")
                                if (AndroidState.qrStatus === "error") return Translation.tr("Pairing failed.")
                                return Translation.tr("Waiting for phone to scan QR code...")
                            }
                            color: IrisStyle.text
                            font.pixelSize: IrisStyle.typeCaption
                            font.weight: IrisStyle.weight(Font.Bold)
                        }
                    }

                    IrisText {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        text: Translation.tr("1. On your phone: Developer options > Wireless debugging\n2. Tap 'Pair device with QR code' and point camera here.")
                        color: IrisStyle.subtext
                        font.pixelSize: Math.max(9, Math.round(10 * root.d))
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Math.round(8 * root.d)

                        IrisButton {
                            text: Translation.tr("Regenerate QR Code")
                            onClicked: AndroidState.startQrPairing()
                        }
                    }
                }
            }

            // TAB 2: MANUAL PAIRING CODE
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.activeTab === "manual"
                spacing: Math.round(8 * root.d)

                IrisText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: Translation.tr("In 'Wireless debugging', tap 'Pair with pairing code'. Enter IP, popup port and 6-digit code:")
                    color: IrisStyle.subtext
                    font.pixelSize: Math.max(9, Math.round(10.5 * root.d))
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)

                    // IP Field
                    IrisPlate {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 2
                        implicitHeight: Math.round(34 * root.d)
                        radius: IrisStyle.radiusRow
                        color: IrisStyle.fillQuiet

                        TextInput {
                            id: manualIp
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * root.d)
                            anchors.rightMargin: Math.round(10 * root.d)
                            verticalAlignment: TextInput.AlignVCenter
                            color: IrisStyle.text
                            font.family: IrisStyle.fontMono
                            font.pixelSize: IrisStyle.typeMeta
                            clip: true
                            text: AndroidState.deviceIp.length > 0 ? AndroidState.deviceIp : "192.168.1.50"
                        }
                    }

                    // Pairing Port Field
                    IrisPlate {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: Math.round(34 * root.d)
                        radius: IrisStyle.radiusRow
                        color: IrisStyle.fillQuiet

                        TextInput {
                            id: manualPairPort
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(8 * root.d)
                            anchors.rightMargin: Math.round(8 * root.d)
                            verticalAlignment: TextInput.AlignVCenter
                            color: IrisStyle.text
                            font.family: IrisStyle.fontMono
                            font.pixelSize: IrisStyle.typeMeta
                            clip: true
                            text: ""

                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: manualPairPort.text.length === 0 && !manualPairPort.activeFocus
                                text: Translation.tr("Pair port")
                                color: IrisStyle.muted
                                font.pixelSize: IrisStyle.typeMeta
                            }
                        }
                    }

                    // 6-digit Code Field
                    IrisPlate {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: Math.round(34 * root.d)
                        radius: IrisStyle.radiusRow
                        color: IrisStyle.fillQuiet

                        TextInput {
                            id: manualCode
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(8 * root.d)
                            anchors.rightMargin: Math.round(8 * root.d)
                            verticalAlignment: TextInput.AlignVCenter
                            color: IrisStyle.text
                            font.family: IrisStyle.fontMono
                            font.pixelSize: IrisStyle.typeMeta
                            clip: true
                            text: ""

                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: manualCode.text.length === 0 && !manualCode.activeFocus
                                text: Translation.tr("6-digit code")
                                color: IrisStyle.muted
                                font.pixelSize: IrisStyle.typeMeta
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Math.round(8 * root.d)

                    // Connect Port Field (Optional if different)
                    IrisPlate {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 1
                        implicitHeight: Math.round(34 * root.d)
                        radius: IrisStyle.radiusRow
                        color: IrisStyle.fillQuiet

                        TextInput {
                            id: manualConnectPort
                            anchors.fill: parent
                            anchors.leftMargin: Math.round(10 * root.d)
                            anchors.rightMargin: Math.round(10 * root.d)
                            verticalAlignment: TextInput.AlignVCenter
                            color: IrisStyle.text
                            font.family: IrisStyle.fontMono
                            font.pixelSize: IrisStyle.typeMeta
                            clip: true
                            text: ""

                            IrisText {
                                anchors.verticalCenter: parent.verticalCenter
                                visible: manualConnectPort.text.length === 0 && !manualConnectPort.activeFocus
                                text: Translation.tr("Connection port (main screen, e.g. 39485)")
                                color: IrisStyle.muted
                                font.pixelSize: IrisStyle.typeMeta
                            }
                        }
                    }

                    IrisButton {
                        emphasized: true
                        text: Translation.tr("Pair and Connect")
                        onClicked: {
                            AndroidState.pairAndConnect(
                                manualIp.text.trim(),
                                manualPairPort.text.trim(),
                                manualCode.text.trim(),
                                manualConnectPort.text.trim()
                            )
                        }
                    }
                }
            }

            // TAB 3: USB TO WI-FI (1-CLICK)
            ColumnLayout {
                Layout.fillWidth: true
                visible: root.activeTab === "usb"
                spacing: Math.round(8 * root.d)

                IrisText {
                    Layout.fillWidth: true
                    wrapMode: Text.WordWrap
                    text: Translation.tr("Connect your phone via USB cable once to enable permanent wireless mode on port 5555. No QR scanning or pairing codes needed.")
                    color: IrisStyle.subtext
                    font.pixelSize: Math.max(9, Math.round(10.5 * root.d))
                }

                RowLayout {
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Math.round(8 * root.d)

                    IrisButton {
                        emphasized: true
                        text: Translation.tr("Enable permanent Wi-Fi (adb tcpip 5555)")
                        onClicked: AndroidState.enableUsbTcpip()
                    }
                }
            }

            // Live Output / Status
            IrisPlate {
                Layout.fillWidth: true
                visible: AndroidState.statusMessage.length > 0
                implicitHeight: statusRow.implicitHeight + Math.round(10 * root.d)
                radius: IrisStyle.radiusTile
                color: IrisStyle.fillQuiet

                RowLayout {
                    id: statusRow
                    anchors.fill: parent
                    anchors.margins: Math.round(6 * root.d)
                    spacing: Math.round(6 * root.d)

                    IrisSquircle {
                        width: Math.round(16 * root.d)
                        height: width
                        glyph: "info"
                        tint: IrisStyle.accent
                    }

                    IrisText {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: AndroidState.statusMessage
                        color: IrisStyle.text
                        font.pixelSize: Math.max(9, Math.round(10 * root.d))
                    }
                }
            }
        }
    }
}
