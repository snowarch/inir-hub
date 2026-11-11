pragma ComponentBehavior: Bound

// The desktop face: a plate of glowing glyphs filling the widget's box (any size the person drags), with a readout
// under it like a print's.
// AbstractBackgroundWidget places, drags and scales it; AfterglyphView draws; this file only lays out.

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.afterglyph"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, x: 240, y: 240 })
    needsColText: true
    resizeMinWidth: 140
    resizeMinHeight: 100
    resizeMaxWidth: 2400
    resizeMaxHeight: 1600
    // The plate is the picture's own black, drawn by the shader.
    widgetSurfaceEnabled: false

    readonly property bool caption: (root._readConfigKey("caption") ?? true) === true
    readonly property int gap: Math.round(8 * root.scaleFactor)
    readonly property int plateWidth: root.width
    readonly property int plateHeight: Math.max(1, root.height - (label.visible ? root.gap + label.implicitHeight : 0))

    AfterglyphView {
        id: view
        width: root.plateWidth
        height: root.plateHeight
        plate: (root._readConfigKey("plate") ?? true) === true
        radius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : root.widgetCardRadius
        theme: [Qt.darker(root.widgetAccentVisible, 2.2), root.widgetAccentVisible, Qt.lighter(root.widgetAccentVisible, 1.7),
            root.widgetAccent3]
        live: root.animationsActive
    }

    // Nothing to draw: say why, on the same plate.
    Rectangle {
        anchors.fill: view
        visible: view.message.length > 0 && !view.drawn
        radius: view.radius
        color: ColorUtils.applyAlpha(root.widgetInk, 0.08)
        border.width: 1
        border.color: ColorUtils.applyAlpha(root.widgetInk, 0.16)

        StyledText {
            anchors.fill: parent
            anchors.margins: Math.round(16 * root.scaleFactor)
            text: view.message
            wrapMode: Text.WordWrap
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            color: root.widgetInkMuted
        }
    }

    Item {
        id: label
        visible: root.caption && view.drawn
        y: view.height + root.gap
        width: view.width
        implicitHeight: grid.implicitHeight

        StyledText {
            anchors.left: parent.left
            anchors.right: grid.left
            anchors.rightMargin: root.gap * 2
            text: view.name
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: root.widgetInk
        }
        StyledText {
            id: grid
            anchors.right: parent.right
            text: view.tag
            font.family: root.widgetNumbersFamily
            font.features: ({ "tnum": 1 })
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: root.widgetInkMuted
        }
    }
}
