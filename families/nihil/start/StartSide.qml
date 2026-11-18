pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// Start's right column under its search: the four home folders (lit and dark in turn), storage and memory as filled
// bars, what plays beside the weather, the battery beside the power keys.
Column {
    id: root

    property real w: NihilStyle.cells(4)
    property bool live: true
    readonly property real c: NihilStyle.cell
    readonly property real g: NihilStyle.cellGap
    signal done()

    spacing: root.g

    function gb(bytes: real): string { return Math.round(bytes / 1e9) + "GB" }

    // Folders.
    Rectangle {
        width: root.w
        height: NihilStyle.s(64) * 2 + root.g * 3
        radius: NihilStyle.s(20)
        color: NihilStyle.pieceRaised
        Grid {
            anchors.centerIn: parent
            columns: 2
            spacing: root.g
            Repeater {
                model: [
                    { icon: "download", name: Translation.tr("Downloads"), url: Directories.downloads },
                    { icon: "description", name: Translation.tr("Documents"), url: Directories.documents },
                    { icon: "image", name: Translation.tr("Pictures"), url: Directories.pictures },
                    { icon: "music_note", name: Translation.tr("Music"), url: Directories.music }
                ]
                delegate: NButton {
                    id: folder
                    required property var modelData
                    required property int index
                    width: (root.w - root.g * 3) / 2
                    height: NihilStyle.s(64)
                    square: true
                    radius: NihilStyle.s(16)
                    lit: folder.index === 1 || folder.index === 2
                    onClicked: { Qt.openUrlExternally(folder.modelData.url); root.done() }
                    Column {
                        anchors.centerIn: parent
                        spacing: NihilStyle.s(4)
                        NIcon { anchors.horizontalCenter: parent.horizontalCenter; text: folder.modelData.icon; size: NihilStyle.s(18); color: folder.ink }
                        NText {
                            anchors.horizontalCenter: parent.horizontalCenter
                            serif: true
                            text: folder.modelData.name
                            font.pixelSize: NihilStyle.textSmall
                            color: folder.ink
                        }
                    }
                }
            }
        }
    }

    // Storage and memory.
    component Meter: Row {
        id: meter
        property real value: 0
        property string label: ""
        property string glyph: ""
        spacing: root.g
        NLevel {
            width: root.w - NihilStyle.s(44) - root.g
            height: NihilStyle.s(44)
            radius: height / 2
            vertical: false
            value: meter.value
            label: meter.label
            enabled: false
        }
        NButton {
            width: NihilStyle.s(44); height: width
            icon: meter.glyph
            iconSize: NihilStyle.s(18)
            onClicked: { AppLauncher.launch("taskManager"); root.done() }
        }
    }
    Meter {
        value: ResourceUsage.diskUsedPercentage
        label: root.gb(ResourceUsage.diskUsed) + "/" + root.gb(ResourceUsage.diskTotal)
        glyph: "storage"
    }
    Meter {
        value: ResourceUsage.memoryUsedPercentage
        label: Math.round(ResourceUsage.memoryUsed / 1048576) + "GB/" + Math.round(ResourceUsage.memoryTotal / 1048576) + "GB"
        glyph: "memory"
    }

    // What plays, the weather.
    Row {
        spacing: root.g
        readonly property real h: NihilStyle.s(124)
        StartMusic {
            width: root.w - weather.width - root.g
            height: parent.h
            live: root.live
        }
        Rectangle {
            id: weather
            readonly property var wx: Weather.data ?? ({})
            readonly property bool has: Weather.hasData ?? false
            width: NihilStyle.s(94)
            height: parent.h
            radius: width / 2
            color: NihilStyle.accent
            Column {
                anchors.centerIn: parent
                spacing: NihilStyle.s(10)
                DotText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: weather.has ? String(Math.round(Number(String(weather.wx.temp ?? "0").replace(/[^0-9.-]/g, "")))) : "--"
                    color: NihilStyle.onAccent
                    dot: NihilStyle.s(4)
                    fitWidth: weather.width - NihilStyle.s(24)
                }
                NText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: Math.min(implicitWidth, weather.width - NihilStyle.s(16))
                    mono: true
                    text: (weather.has ? Weather.describeWeather(weather.wx.wCode, Weather.isNightNow()) : Translation.tr("No weather")).toUpperCase()
                    font.pixelSize: NihilStyle.s(10)
                    color: NihilStyle.onAccent
                }
            }
        }
    }

    // Battery, power.
    Row {
        spacing: root.g
        Rectangle {
            id: battery
            width: NihilStyle.s(64); height: width
            radius: width / 2
            color: Battery.available && Battery.isLow && !Battery.isCharging ? NihilStyle.pieceRaised : NihilStyle.accent
            NText {
                anchors.centerIn: parent
                mono: true
                text: Battery.available ? Math.round(Battery.percentage * 100) + "%" : "AC"
                color: battery.color === NihilStyle.accent ? NihilStyle.onAccent : NihilStyle.accent
            }
        }
        NButton {
            width: root.w - battery.width - root.g
            height: battery.height
            Row {
                anchors.centerIn: parent
                spacing: NihilStyle.s(26)
                component Act: NIcon {
                    required property string action
                    size: NihilStyle.s(22)
                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -NihilStyle.s(8)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.done()
                            if (parent.action === "poweroff") Session.poweroff()
                            else if (parent.action === "reboot") Session.reboot()
                            else Session.lock()
                        }
                    }
                }
                Act { action: "poweroff"; text: "power_settings_new" }
                Act { action: "reboot"; text: "restart_alt"; color: NihilStyle.accent }
                Act { action: "lock"; text: "lock" }
            }
        }
    }
}
