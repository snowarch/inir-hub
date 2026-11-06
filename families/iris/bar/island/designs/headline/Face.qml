pragma ComponentBehavior: Bound
import QtQuick
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

// Headline: the time as a poster sets it, one tall condensed figure; beside it the place in spaced capitals over the
// sky in heavy condensed capitals, then the temperature in the clock's accent. Without weather, the day and the date.
// The person may keep the day and the date over the sky, and drop the temperature (iris.bar.faces.headline).
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property date now: DateTime.clock.date
    readonly property var options: Config.options?.iris?.bar?.faces?.headline ?? ({})
    readonly property bool sky: root.options.beside !== "date" && Weather.enabled && Weather.hasData
    readonly property bool roomy: root.h >= Math.round(34 * root.d)
    readonly property color mark: root.island?.clockAccent ?? IrisStyle.accent
    readonly property real contentWidth: row.implicitWidth
    readonly property string condensed: "Google Sans Flex" // iris-literal: the poster figure needs a width axis

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(10 * root.d)
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: DateTime.timeDisplay
            color: IrisStyle.text
            font.family: root.condensed
            font.variableAxes: ({ "wdth": 25, "wght": 800, "opsz": 72 })
            font.pixelSize: Math.round(root.h * 0.74)
            font.features: ({ "tnum": 1 })
            renderType: Text.QtRendering
        }
        Column {
            anchors.verticalCenter: parent.verticalCenter
            spacing: -Math.round(1 * root.d)
            IrisText {
                visible: root.roomy
                text: (root.sky && Weather.showVisibleCity ? Weather.visibleCity
                    : Translation.locale.dayName(root.now.getDay(), Locale.LongFormat)).toUpperCase()
                color: IrisStyle.textTertiary
                font.pixelSize: Math.max(8, Math.round(root.h * 0.2))
                font.weight: IrisStyle.weight(Font.Medium)
                font.letterSpacing: 1.2 * root.d
            }
            Text {
                text: (root.sky ? String(Weather.data.description) : Translation.locale.toString(root.now, "d MMMM")).toUpperCase()
                color: IrisStyle.text
                font.family: root.condensed
                font.variableAxes: ({ "wdth": 40, "wght": 760, "opsz": 36 })
                font.pixelSize: Math.round(root.h * (root.roomy ? 0.34 : 0.42))
                renderType: Text.QtRendering
            }
        }
        Text {
            visible: root.sky && root.options.temperature !== false
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round(parseFloat(String(Weather.data.temp))) + "°"
            color: root.mark
            font.family: root.condensed
            font.variableAxes: ({ "wdth": 25, "wght": 760, "opsz": 72 })
            font.pixelSize: Math.round(root.h * 0.6)
            renderType: Text.QtRendering
        }
    }
}
