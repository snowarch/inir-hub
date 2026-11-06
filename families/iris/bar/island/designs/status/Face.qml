pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import Quickshell.Bluetooth

// Status: a status bar in one capsule, the time at the start. At the end, what this machine has: the connection (a
// cable, Wi-Fi's bars, or none), the sound when it is off, then the battery as a lit capsule with its figure; with no
// battery, the charge of a headset that has one, else the weather, else the day.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real contentWidth: clock.implicitWidth + ends.implicitWidth + Math.round(46 * root.d)
    readonly property bool cable: Network.ethernet
    readonly property bool wireless: !root.cable && Network.wifiEnabled && Network.online
    readonly property int bars: Math.max(1, Math.min(4, Math.ceil(Number(Network.networkStrength) / 25)))
    readonly property var headset: (Bluetooth.devices?.values ?? []).find(device => device?.connected && device?.batteryAvailable) ?? null
    readonly property bool sky: Weather.enabled && Weather.hasData
    // What the capsule carries: "battery", "headset", "sky" or "day".
    readonly property string carry: Battery.available ? "battery" : root.headset ? "headset" : root.sky ? "sky" : "day"
    readonly property real level: root.carry === "battery" ? Battery.percentage : root.carry === "headset" ? Number(root.headset.battery) : 0
    readonly property color pill: root.carry === "battery" && Battery.isLow && !Battery.isCharging ? IrisStyle.danger
        : root.carry === "headset" && root.level <= 0.2 ? IrisStyle.danger
        : Battery.isCharging && root.carry === "battery" ? IrisStyle.identity.green : IrisStyle.text
    readonly property string pillText: root.carry === "battery" || root.carry === "headset" ? String(Math.round(root.level * 100))
        : root.carry === "sky" ? Math.round(parseFloat(String(Weather.data.temp))) + "°"
        : String(DateTime.clock.date.getDate())
    readonly property string lead: root.carry === "headset" ? "headphones"
        : root.carry === "sky" ? (Icons.getWeatherIcon(Weather.data.wCode, Weather.isNightNow()) ?? "cloud")
        : root.carry === "day" ? "calendar_today" : Battery.isCharging ? "bolt" : ""

    IrisClock {
        id: clock
        anchors.left: parent.left
        anchors.leftMargin: Math.round(18 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: root.island?.clockAccent ?? IrisStyle.accent
    }
    Row {
        id: ends
        anchors.right: parent.right
        anchors.rightMargin: Math.round(14 * root.d)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Math.round(8 * root.d)
        MaterialSymbol {
            visible: Audio.sink?.audio?.muted ?? false
            anchors.verticalCenter: parent.verticalCenter
            text: "volume_off"
            fill: 1
            iconSize: Math.round(15 * root.d)
            color: IrisStyle.danger
        }
        // A cable is its port; Wi-Fi rises in four bars lit to its strength; nothing, the struck mark.
        MaterialSymbol {
            visible: !root.wireless
            anchors.verticalCenter: parent.verticalCenter
            text: root.cable ? "settings_ethernet" : "signal_disconnected"
            fill: 1
            iconSize: Math.round(15 * root.d)
            color: root.cable ? IrisStyle.text : IrisStyle.textTertiary
        }
        Row {
            visible: root.wireless
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(1.5 * root.d))
            Repeater {
                model: 4
                Rectangle {
                    required property int index
                    anchors.bottom: parent.bottom
                    width: Math.max(2, Math.round(3 * root.d))
                    height: Math.round((5 + index * 2.5) * root.d)
                    radius: width / 2
                    color: index < root.bars ? IrisStyle.text : IrisStyle.fillActive
                }
            }
        }
        MaterialSymbol {
            visible: root.lead.length > 0 && root.carry !== "battery"
            anchors.verticalCenter: parent.verticalCenter
            text: root.lead
            fill: 1
            iconSize: Math.round(15 * root.d)
            color: IrisStyle.textSecondary
        }
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.max(1, Math.round(1 * root.d))
            Rectangle {
                width: Math.max(Math.round(30 * root.d), pillLabel.implicitWidth + Math.round(12 * root.d))
                height: Math.round(17 * root.d)
                radius: height / 2
                color: root.pill
                Row {
                    anchors.centerIn: parent
                    spacing: Math.round(2 * root.d)
                    MaterialSymbol {
                        visible: root.carry === "battery" && Battery.isCharging
                        anchors.verticalCenter: parent.verticalCenter
                        text: "bolt"
                        fill: 1
                        iconSize: Math.round(11 * root.d)
                        color: IrisStyle.onTintFor(root.pill)
                    }
                    IrisText {
                        id: pillLabel
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.pillText
                        color: IrisStyle.onTintFor(root.pill)
                        font.pixelSize: Math.round(11 * root.d)
                        font.weight: IrisStyle.weight(Font.Bold)
                        font.features: ({ "tnum": 1 })
                    }
                }
            }
            // The battery's nub: only a battery has one.
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: root.carry === "battery" || root.carry === "headset"
                width: Math.max(1.5, Math.round(2 * root.d))
                height: Math.round(6 * root.d)
                radius: width / 2
                color: IrisStyle.trackOf(root.pill)
            }
        }
    }
}
