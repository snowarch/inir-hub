pragma ComponentBehavior: Bound

// The Material face: a card on the desktop. AbstractBackgroundWidget gives it placement, dragging,
// scaling, per-monitor positions and root.colText, the ink that stays readable over the wallpaper.
// Colours, corners and type come from Appearance, so the user's theme reaches the card.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.__ID__"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, x: 240, y: 240 })
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 120
    resizeMinHeight: 64

    // configKeys from widget.json, read null-safe with the same fallbacks.
    readonly property string label: String(root._readConfigKey("label") ?? "Now")

    readonly property int pad: Math.round(16 * root.scaleFactor)
    implicitWidth: Math.max(Math.round(160 * root.scaleFactor), body.implicitWidth + root.pad * 2)
    implicitHeight: body.implicitHeight + root.pad * 2

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
            text: root.label
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.colText, 0.65)
        }
        StyledText {
            text: DateTime.time
            font.family: Appearance.font.family.numbers
            font.pixelSize: Math.round(34 * root.scaleFactor)
            font.weight: Font.DemiBold
            color: root.colText
        }
    }
}
