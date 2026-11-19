pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Bluetooth
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// What a control leads to, on the same pane: the Wi-Fi networks, the Bluetooth devices, or the sound outputs and inputs.
// A locked network asks for its password in place.
Item {
    id: root

    property string page: ""

    readonly property bool wifi: root.page === "wifi"
    readonly property bool bluetooth: root.page === "bluetooth"
    readonly property bool sound: root.page === "output" || root.page === "input"
    readonly property bool live: root.visible && root.page.length > 0
    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool searching: (root.wifi && Network.wifiEnabled && Network.wifiScanning)
        || (root.bluetooth && (root.adapter?.discovering ?? false))

    readonly property var rows: {
        if (root.wifi)
            return [...Network.wifiNetworks].filter(ap => ap.ssid.length > 0)
                .sort((a, b) => (b.active - a.active) || (b.strength - a.strength))
        if (root.bluetooth)
            return [...(Bluetooth.devices?.values ?? [])]
                .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired)
                    || String(a.name).localeCompare(String(b.name)))
        if (root.page === "output")
            return Audio.outputDevices
        if (root.page === "input")
            return Audio.inputDevices
        return []
    }

    signal back()
    signal picked(string page)

    function _refresh(): void {
        if (root.live && root.wifi && Network.wifiEnabled)
            Network.rescanWifi()
        if (root.adapter)
            root.adapter.discovering = root.live && root.bluetooth && root.adapter.enabled
    }

    onLiveChanged: root._refresh()
    onPageChanged: root._refresh()

    Item {
        id: head
        width: parent.width
        height: NihilStyle.s(40)

        NButton {
            id: backKey
            anchors.verticalCenter: parent.verticalCenter
            icon: "chevron_left"
            radius: width / 2
            Accessible.name: Translation.tr("Back")
            onClicked: root.back()
        }
        NText {
            anchors.left: backKey.right
            anchors.leftMargin: NihilStyle.s(8)
            anchors.right: radio.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.sound
            text: root.wifi ? Translation.tr("Wi-Fi") : Translation.tr("Bluetooth")
            font.pixelSize: NihilStyle.textLarge
            font.weight: Font.Medium
        }
        NSegmented {
            anchors.left: backKey.right
            anchors.leftMargin: NihilStyle.s(8)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: root.sound
            options: [
                { value: "output", label: Translation.tr("Output") },
                { value: "input", label: Translation.tr("Input") }
            ]
            current: root.page
            onPicked: value => root.picked(value)
        }
        NSwitch {
            id: radio
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.sound
            on: root.wifi ? Network.wifiEnabled : (root.adapter?.enabled ?? false)
            onToggled: {
                if (root.wifi)
                    Network.enableWifi(!Network.wifiEnabled)
                else if (root.adapter)
                    root.adapter.enabled = !root.adapter.enabled
            }
        }
    }

    ListView {
        id: list
        y: head.height + NihilStyle.gap
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: NihilStyle.gap
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows

        delegate: Loader {
            id: slot
            required property var modelData
            width: list.width
            sourceComponent: root.wifi ? wifiRow : root.bluetooth ? deviceRow : soundRow
            onLoaded: slot.item.entry = Qt.binding(() => slot.modelData)
        }
    }

    Column {
        anchors.horizontalCenter: list.horizontalCenter
        y: list.y + (list.height - height) / 2
        width: parent.width
        visible: list.count === 0
        spacing: NihilStyle.s(8)

        NIcon {
            id: waiting
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.searching ? "restart" : root.wifi ? "wifi_off" : root.bluetooth ? "bluetooth_disabled" : "speaker"
            size: NihilStyle.s(30)
            color: NihilStyle.inkSoft

            RotationAnimator on rotation {
                running: root.searching && waiting.visible
                from: 0
                to: 360
                duration: 1400
                loops: Animation.Infinite
            }
        }
        NText {
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.Wrap
            color: NihilStyle.inkSoft
            text: root.wifi ? (Network.wifiEnabled ? Translation.tr("Looking for networks") : Translation.tr("Wi-Fi is off"))
                : root.bluetooth ? (!root.adapter ? Translation.tr("No Bluetooth here")
                    : root.adapter.enabled ? Translation.tr("Looking for devices") : Translation.tr("Bluetooth is off"))
                : Translation.tr("No devices")
        }
    }

    // The row every list shares: a glyph, a name over one line, marked while in use.
    component Line: Item {
        id: line

        property string glyph: ""
        property string name: ""
        property string note: ""
        property bool current: false

        signal tapped()

        width: parent?.width ?? 0
        height: NihilStyle.s(60)

        Rectangle {
            anchors.fill: parent
            radius: height / 2
            color: line.current ? NihilStyle.accent : press.containsMouse ? NihilStyle.pieceRaised : NihilStyle.piece
            Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        }

        MouseArea {
            id: press
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: line.tapped()
        }
        NIcon {
            id: lineGlyph
            x: NihilStyle.s(20)
            anchors.verticalCenter: parent.verticalCenter
            text: line.glyph
            size: NihilStyle.s(20)
            color: line.current ? NihilStyle.accentInk : NihilStyle.ink
        }
        Column {
            anchors.left: lineGlyph.right
            anchors.leftMargin: NihilStyle.s(14)
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(22)
            anchors.verticalCenter: parent.verticalCenter

            NText {
                width: parent.width
                text: line.name
                elide: Text.ElideRight
                font.weight: Font.Medium
                color: line.current ? NihilStyle.accentInk : NihilStyle.ink
            }
            NText {
                width: parent.width
                visible: line.note.length > 0
                text: line.note
                elide: Text.ElideRight
                font.pixelSize: NihilStyle.textSmall
                color: line.current ? Qt.alpha(NihilStyle.accentInk, 0.72) : NihilStyle.inkSoft
            }
        }
    }

    Component {
        id: wifiRow

        Column {
            id: net

            property var entry: null

            width: list.width
            spacing: NihilStyle.s(2)

            Line {
                width: net.width
                current: net.entry?.active ?? false
                glyph: "wifi"
                name: net.entry?.ssid ?? ""
                note: net.entry?.active ? Translation.tr("Connected")
                    : net.entry?.isSecure ? Translation.tr("Locked") : Translation.tr("Open")
                onTapped: {
                    if (!net.entry)
                        return
                    if (net.entry.active)
                        Network.disconnectWifiNetwork()
                    else
                        Network.connectToWifiNetwork(net.entry)
                }
            }
            NField {
                id: pass
                visible: net.entry?.askingPassword ?? false
                width: net.width
                glyph: "password"
                placeholder: Translation.tr("Password for %1").arg(net.entry?.ssid ?? "")
                echoMode: TextInput.Password
                onVisibleChanged: if (pass.visible) pass.take()
                onEntered: if (pass.text.length > 0) Network.changePassword(net.entry, pass.text)
            }
        }
    }

    Component {
        id: deviceRow

        Line {
            id: device

            property var entry: null

            width: list.width
            current: device.entry?.connected ?? false
            glyph: "bluetooth"
            name: device.entry?.name || device.entry?.deviceName || device.entry?.address || ""
            note: device.entry?.connected
                ? (device.entry?.batteryAvailable
                    ? Translation.tr("Connected, %1%").arg(Math.round(device.entry.battery * 100))
                    : Translation.tr("Connected"))
                : device.entry?.paired ? Translation.tr("Paired") : Translation.tr("Tap to pair")
            onTapped: {
                if (!device.entry)
                    return
                if (device.entry.connected)
                    device.entry.disconnect()
                else if (device.entry.paired)
                    device.entry.connect()
                else
                    device.entry.pair()
            }
        }
    }

    Component {
        id: soundRow

        Line {
            id: node

            property var entry: null
            readonly property var inUse: root.page === "output" ? (Audio.rawSink ?? Audio.sink) : Audio.source

            width: list.width
            current: !!node.entry && !!node.inUse && node.entry.id === node.inUse.id
            glyph: root.page === "input" ? "mic"
                : String(node.entry?.name ?? "").includes("bluez") ? "headphones" : "speaker"
            name: Audio.friendlyDeviceName(node.entry)
            onTapped: {
                if (!node.entry)
                    return
                if (root.page === "output")
                    Audio.setDefaultSink(node.entry)
                else
                    Audio.setDefaultSource(node.entry)
            }
        }
    }
}
