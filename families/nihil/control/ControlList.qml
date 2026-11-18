pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import qs
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// What a key of Control leads to, in the same piece: the Wi-Fi networks, the Bluetooth devices or the sound outputs
// and inputs. Its head: back, the list's name, its radio. A row in use is lit; a locked network asks for its password
// in place.
Item {
    id: root

    property string page: ""
    readonly property bool live: root.visible && root.page.length > 0
    signal back()

    readonly property bool wifi: root.page === "wifi"
    readonly property bool bluetooth: root.page === "bluetooth"
    readonly property bool sound: root.page === "output" || root.page === "input"
    readonly property var adapter: Bluetooth.defaultAdapter

    readonly property var rows: {
        if (root.wifi)
            return [...Network.wifiNetworks].filter(ap => ap.ssid.length > 0)
                .sort((a, b) => (b.active - a.active) || (b.strength - a.strength))
        if (root.bluetooth)
            return [...(Bluetooth.devices?.values ?? [])]
                .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || String(a.name).localeCompare(String(b.name)))
        if (root.page === "output") return Audio.outputDevices
        if (root.page === "input") return Audio.inputDevices
        return []
    }

    onLiveChanged: {
        if (root.live && root.wifi && Network.wifiEnabled) Network.rescanWifi()
        if (root.adapter) root.adapter.discovering = root.live && root.bluetooth && root.adapter.enabled
    }
    onPageChanged: {
        if (root.live && root.wifi && Network.wifiEnabled) Network.rescanWifi()
        if (root.adapter) root.adapter.discovering = root.live && root.bluetooth && root.adapter.enabled
    }

    Item {
        id: head
        width: parent.width
        height: NihilStyle.cell
        NButton {
            id: backKey
            width: NihilStyle.s(40); height: width
            anchors.verticalCenter: parent.verticalCenter
            tone: NihilStyle.pieceRaised
            icon: "chevron_left"
            iconSize: NihilStyle.s(22)
            onClicked: root.back()
        }
        NText {
            anchors.left: backKey.right
            anchors.leftMargin: NihilStyle.s(10)
            anchors.right: radio.left
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.sound
            text: root.wifi ? Translation.tr("Wi-Fi") : Translation.tr("Bluetooth")
            font.pixelSize: NihilStyle.textLarge
            font.weight: Font.DemiBold
        }
        NSegmented {
            anchors.left: backKey.right
            anchors.leftMargin: NihilStyle.s(8)
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            height: NihilStyle.s(36)
            visible: root.sound
            options: [{ value: "output", label: Translation.tr("Output") }, { value: "input", label: Translation.tr("Input") }]
            current: root.page
            onPicked: value => root.page = value
        }
        NSwitch {
            id: radio
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.sound
            on: root.wifi ? Network.wifiEnabled : (root.adapter?.enabled ?? false)
            onToggled: {
                if (root.wifi) Network.enableWifi(!Network.wifiEnabled)
                else if (root.adapter) root.adapter.enabled = !root.adapter.enabled
            }
        }
    }

    ListView {
        id: list
        y: head.height + NihilStyle.cellGap
        width: parent.width
        height: parent.height - y
        clip: true
        spacing: NihilStyle.s(6)
        boundsBehavior: Flickable.StopAtBounds
        model: root.rows
        visible: count > 0
        delegate: Loader {
            id: slot
            required property var modelData
            width: list.width
            sourceComponent: root.wifi ? wifiRow : root.bluetooth ? deviceRow : soundRow
            onLoaded: slot.item.entry = Qt.binding(() => slot.modelData)
        }
    }

    NEmpty {
        anchors.horizontalCenter: parent.horizontalCenter
        y: head.height + (parent.height - head.height - height) / 2
        width: parent.width - NihilStyle.s(20)
        visible: list.count === 0
        busy: (root.wifi && Network.wifiEnabled && Network.wifiScanning) || (root.bluetooth && (root.adapter?.discovering ?? false))
        glyph: root.wifi ? (Network.wifiEnabled ? "wifi_find" : "wifi_off")
            : root.bluetooth ? (root.adapter?.enabled ? "bluetooth_searching" : "bluetooth_disabled") : "speaker"
        title: root.wifi ? (Network.wifiEnabled ? Translation.tr("Looking for networks") : Translation.tr("Wi-Fi is off"))
            : root.bluetooth ? (!root.adapter ? Translation.tr("No Bluetooth here")
                : root.adapter.enabled ? Translation.tr("Looking for devices") : Translation.tr("Bluetooth is off"))
            : Translation.tr("No devices")
    }

    // The row every list shares: a glyph, a name over one line, lit while in use.
    component Line: Rectangle {
        id: line
        property string glyph: ""
        property string name: ""
        property string note: ""
        property bool current: false
        property bool busy: false
        signal tapped()
        width: parent?.width ?? 0
        height: NihilStyle.s(50)
        radius: NihilStyle.rowRadius
        color: line.current ? NihilStyle.accent : press.containsMouse ? NihilStyle.pieceHover : NihilStyle.pieceRaised
        Behavior on color { ColorAnimation { duration: NihilStyle.quick } }
        readonly property color inkOn: line.current ? NihilStyle.onAccent : NihilStyle.ink
        MouseArea {
            id: press
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: line.tapped()
        }
        NIcon {
            id: lineGlyph
            x: NihilStyle.s(14)
            anchors.verticalCenter: parent.verticalCenter
            text: line.glyph
            size: NihilStyle.s(20)
            color: line.inkOn
        }
        Column {
            anchors.left: lineGlyph.right
            anchors.leftMargin: NihilStyle.s(12)
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(14) + (spin.visible ? spin.width + NihilStyle.s(8) : 0)
            anchors.verticalCenter: parent.verticalCenter
            spacing: NihilStyle.s(1)
            NText {
                width: parent.width
                text: line.name
                font.weight: Font.Medium
                color: line.inkOn
            }
            NText {
                width: parent.width
                visible: line.note.length > 0
                text: line.note
                font.pixelSize: NihilStyle.textSmall
                color: line.inkOn
                opacity: 0.66
            }
        }
        NSpinner {
            id: spin
            visible: line.busy
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(14)
            anchors.verticalCenter: parent.verticalCenter
            width: NihilStyle.s(18); height: width
        }
    }

    Component {
        id: wifiRow
        Column {
            id: net
            property var entry: null
            readonly property var ap: net.entry
            width: list.width
            spacing: NihilStyle.s(6)
            Line {
                width: net.width
                current: net.ap?.active ?? false
                glyph: (net.ap?.strength ?? 0) > 66 ? "network_wifi" : (net.ap?.strength ?? 0) > 33 ? "network_wifi_2_bar" : "network_wifi_1_bar"
                name: net.ap?.ssid ?? ""
                note: net.ap?.active ? Translation.tr("Connected") : (net.ap?.isSecure ? Translation.tr("Locked") : Translation.tr("Open"))
                    + ((net.ap?.bandLabel ?? "").length > 0 ? " · " + net.ap.bandLabel : "")
                onTapped: {
                    if (!net.ap) return
                    if (net.ap.active) Network.disconnectWifiNetwork()
                    else Network.connectToWifiNetwork(net.ap)
                }
            }
            NField {
                id: pass
                visible: net.ap?.askingPassword ?? false
                onVisibleChanged: if (visible) pass.take()
                width: net.width
                height: NihilStyle.s(44)
                glyph: "password"
                placeholder: Translation.tr("Password for %1").arg(net.ap?.ssid ?? "")
                echoMode: TextInput.Password
                onEntered: if (pass.text.length > 0) Network.changePassword(net.ap, pass.text)
            }
        }
    }

    Component {
        id: deviceRow
        Line {
            property var entry: null
            readonly property var device: entry
            width: list.width
            current: device?.connected ?? false
            busy: device?.pairing ?? false
            glyph: BluetoothStatus.iconForDevice ? BluetoothStatus.iconForDevice(device) : "bluetooth"
            name: device?.name || device?.deviceName || device?.address || ""
            note: device?.connected
                ? (device?.batteryAvailable ? Translation.tr("Connected · %1%").arg(Math.round(device.battery * 100)) : Translation.tr("Connected"))
                : device?.paired ? Translation.tr("Paired") : Translation.tr("Tap to pair")
            onTapped: {
                if (!device) return
                if (device.connected) device.disconnect()
                else if (device.paired) device.connect()
                else device.pair()
            }
        }
    }

    Component {
        id: soundRow
        Line {
            property var entry: null
            readonly property var node: entry
            readonly property var inUse: root.page === "output" ? (Audio.rawSink ?? Audio.sink) : Audio.source
            width: list.width
            current: !!node && !!inUse && node.id === inUse.id
            glyph: root.page === "output" ? (String(node?.name ?? "").includes("bluez") ? "headphones" : "speaker") : "mic"
            name: Audio.friendlyDeviceName(node)
            onTapped: {
                if (!node) return
                if (root.page === "output") Audio.setDefaultSink(node)
                else Audio.setDefaultSource(node)
            }
        }
    }
}
