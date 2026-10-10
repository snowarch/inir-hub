pragma ComponentBehavior: Bound

// The Material face: a card on the desktop. It extends AbstractBackgroundWidget, which gives it
// placement, dragging, scaling, per-monitor positions and the ink colour (root.colText) that stays
// readable over whatever wallpaper sits behind it.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets
import "countdown.js" as Countdown

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.countdown"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, x: 240, y: 240 })
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 150
    resizeMinHeight: 90

    readonly property int pad: Math.round(18 * root.scaleFactor)
    implicitWidth: Math.max(Math.round(200 * root.scaleFactor), body.implicitWidth + root.pad * 2)
    implicitHeight: body.implicitHeight + root.pad * 2

    // configKeys from widget.json, read null-safe with the same fallbacks.
    readonly property string label: String(root._readConfigKey("label") ?? "New year")
    readonly property string dateText: String(root._readConfigKey("date") ?? "")
    readonly property var target: Countdown.parse(root.dateText)

    // A countdown needs minutes, not frames: the clock wakes once a minute, and only while shown.
    SystemClock {
        id: clock
        precision: SystemClock.Minutes
        enabled: root.visible
    }
    readonly property var reading: Countdown.describe(root.target, clock.date)

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : Appearance.rounding.large
        color: ColorUtils.applyAlpha(root.colText, Math.max(root.backgroundOpacity, 0.06))
        border.width: root.borderWidth
        border.color: ColorUtils.applyAlpha(root.colText, root.borderOpacity)
    }

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(2 * root.scaleFactor)

        StyledText {
            Layout.fillWidth: true
            text: root.label.toUpperCase()
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            font.weight: Font.DemiBold
            font.letterSpacing: Math.round(1 * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.colText, 0.62)
        }

        RowLayout {
            spacing: Math.round(8 * root.scaleFactor)
            visible: root.reading.valid

            StyledText {
                text: root.reading.figure
                font.family: Appearance.font.family.numbers
                font.pixelSize: Math.round(46 * root.scaleFactor)
                font.weight: Font.Bold
                color: root.reading.past ? ColorUtils.applyAlpha(root.colText, 0.7) : root.colText
            }
            StyledText {
                Layout.alignment: Qt.AlignBaseline
                visible: text.length > 0
                text: root.reading.unit
                font.pixelSize: Math.round(Appearance.font.pixelSize.large * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.colText, 0.72)
            }
        }

        StyledText {
            visible: root.reading.valid
            text: Countdown.dateLine(root.target, root.dateText)
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.colText, 0.55)
        }

        // An unset or mistyped date is a state with a next step, not a blank card.
        RowLayout {
            visible: !root.reading.valid
            spacing: Math.round(8 * root.scaleFactor)
            MaterialSymbol {
                text: "edit_calendar"
                iconSize: Math.round(22 * root.scaleFactor)
                color: root.colText
            }
            StyledText {
                text: "Set a date in the widget's settings"
                font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.colText, 0.8)
            }
        }
    }
}
