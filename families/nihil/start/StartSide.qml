pragma ComponentBehavior: Bound

import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.nihil.style

// Start's other half: what plays, memory and storage, the weather and the charge, the home folders, the power keys.
Column {
    id: root

    readonly property real g: NihilStyle.seam
    readonly property real half: (root.width - root.g) / 2
    readonly property var wx: Weather.data ?? ({})
    readonly property bool hasWeather: Weather.hasData ?? false
    signal done()

    spacing: root.g

    NPlayer {
        width: root.width
        height: NihilStyle.s(132)
    }

    Row {
        spacing: root.g
        NStat {
            width: root.half
            height: NihilStyle.s(112)
            caption: Translation.tr("Memory")
            figure: String(Math.round(ResourceUsage.memoryUsedPercentage * 100))
            unit: "%"
            level: ResourceUsage.memoryUsedPercentage
            interactive: true
            onClicked: { AppLauncher.launch("taskManager"); root.done() }
        }
        NStat {
            width: root.half
            height: NihilStyle.s(112)
            caption: Translation.tr("Storage")
            figure: String(Math.round(ResourceUsage.diskUsedPercentage * 100))
            unit: "%"
            level: ResourceUsage.diskUsedPercentage
            interactive: true
            onClicked: { AppLauncher.launch("taskManager"); root.done() }
        }
    }

    Row {
        spacing: root.g
        NStat {
            width: root.half
            height: NihilStyle.s(112)
            caption: root.hasWeather ? Weather.describeWeather(root.wx.wCode, Weather.isNightNow()) : Translation.tr("Weather")
            figure: root.hasWeather ? String(Math.round(Number(String(root.wx.temp ?? "0").replace(/[^0-9.-]/g, "")))) : "--"
            unit: "°"
        }
        NStat {
            width: root.half
            height: NihilStyle.s(112)
            caption: Battery.available ? (Battery.isCharging ? Translation.tr("Charging") : Translation.tr("Charge")) : Translation.tr("Power")
            figure: Battery.available ? String(Math.round(Battery.percentage * 100)) : "AC"
            unit: Battery.available ? "%" : ""
            level: Battery.available ? Battery.percentage : -1
            strokeColor: Battery.available && Battery.isLow && !Battery.isCharging ? NihilStyle.accent : ink
        }
    }

    Row {
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
                width: (root.width - root.g * 3) / 4
                height: NihilStyle.s(76)
                square: true
                onClicked: { Qt.openUrlExternally(folder.modelData.url); root.done() }
                NIcon {
                    x: NihilStyle.s(10)
                    y: NihilStyle.s(10)
                    text: folder.modelData.icon
                    size: NihilStyle.s(22)
                    color: folder.ink
                }
                NText {
                    x: NihilStyle.s(10)
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: NihilStyle.s(8)
                    width: parent.width - NihilStyle.s(14)
                    text: folder.modelData.name
                    font.pixelSize: NihilStyle.textMicro
                    font.weight: Font.Bold
                    color: folder.ink
                }
            }
        }
    }

    Row {
        spacing: root.g
        NButton {
            width: (root.width - root.g * 2) / 3
            height: NihilStyle.s(52)
            square: true
            icon: "lock"
            iconSize: NihilStyle.s(22)
            onClicked: { root.done(); Session.lock() }
        }
        NButton {
            width: (root.width - root.g * 2) / 3
            height: NihilStyle.s(52)
            square: true
            icon: "bedtime"
            iconSize: NihilStyle.s(22)
            onClicked: { root.done(); Session.suspend() }
        }
        NButton {
            width: (root.width - root.g * 2) / 3
            height: NihilStyle.s(52)
            square: true
            lit: true
            icon: "power_settings_new"
            iconSize: NihilStyle.s(22)
            onClicked: { root.done(); GlobalStates.sessionOpen = true }
        }
    }
}
