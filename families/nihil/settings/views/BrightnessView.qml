pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.nihil.style

// How bright each screen is, for the screens that can say.
Column {
    id: root

    readonly property var monitors: Quickshell.screens
        .map(screen => ({ name: screen.name, monitor: Brightness.getMonitorForScreen(screen) }))
        .filter(entry => !!entry.monitor && entry.monitor.ready && Number.isFinite(entry.monitor.brightness))

    spacing: NihilStyle.s(10)

    NEmpty {
        visible: root.monitors.length === 0
        width: root.width
        glyph: "brightness_empty"
        title: Translation.tr("These screens set their own brightness")
        line: Translation.tr("Use the buttons on the screen itself.")
    }
    Repeater {
        model: root.monitors
        Row {
            id: line
            required property var modelData
            width: root.width
            spacing: NihilStyle.s(12)
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(86)
                figures: true
                text: line.modelData.name
                font.pixelSize: NihilStyle.textSmall
                color: NihilStyle.inkSoft
            }
            NSlider {
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width - NihilStyle.s(160)
                stepSize: 0.01
                value: line.modelData.monitor.brightness
                name: line.modelData.name
                onMoved: value => line.modelData.monitor.setBrightness(value)
            }
            NText {
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(38)
                horizontalAlignment: Text.AlignRight
                figures: true
                text: Math.round(line.modelData.monitor.brightness * 100) + "%"
                font.pixelSize: NihilStyle.textSmall
            }
        }
    }
}
