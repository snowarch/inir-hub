pragma ComponentBehavior: Bound

// The Material face, built the way the Hub's own widgets are. Keep the structure, change what it shows.
//
// AbstractBackgroundWidget gives it placement, dragging, scaling, per-monitor positions, the user's
// widget design and root.widgetInk, the ink that stays readable over the wallpaper. Every colour,
// corner, shape and font below comes from the shell, so the user's theme reaches the card.
//
// Two looks, like the built-in widgets:
//   Shape       a Material shape the user picks, holding the glyph; eyebrow, figure, detail and a
//               wavy bar beside it. Change the shape when the state changes and it morphs on its own.
//   Instrument  the iNstrument grammar. It is also drawn whenever the user's global widget design is
//               iNstrument or Readout, so your widget never sticks out among the built-ins.
// This example shows the time, the date and how much of the day has gone by.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets
import qs.modules.background.widgets.instrument

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.__ID__"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie7Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240 })
    // Its ink is read from the wallpaper under it (or from the plate, when there is one).
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 220
    resizeMinHeight: 90

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    // iNstrument is borderless by contract; the shape look sits on the shared plate.
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie7Sided")

    // ── What it shows (replace this part) ────────────────────
    // configKeys from widget.json, read null-safe with the same fallbacks.
    readonly property string label: String(root._readConfigKey("label") ?? "Now")
    readonly property var now: DateTime.clock.date
    readonly property real dayFraction: (root.now.getHours() * 60 + root.now.getMinutes()) / 1440
    readonly property bool daytime: root.now.getHours() >= 7 && root.now.getHours() < 19

    // ── Geometry: everything derives from the scale ──────────
    readonly property int pad: Math.round(16 * root.scaleFactor)
    readonly property int shapeSize: Math.round(84 * root.scaleFactor)
    readonly property int infoWidth: Math.round(164 * root.scaleFactor)
    readonly property int instrumentMargin: Math.round(14 * root.scaleFactor)
    implicitWidth: root.instrument ? Math.round(250 * root.scaleFactor)
        : root.pad * 2 + root.shapeSize + Math.round(16 * root.scaleFactor) + root.infoWidth
    implicitHeight: root.instrument ? instrumentBody.implicitHeight + root.instrumentMargin * 2
        : Math.max(root.shapeSize, info.implicitHeight) + root.pad * 2

    // The plate every built-in widget sits on: the user's design, opacity, outline, blur and corners.
    WidgetSurface {
        anchors.fill: parent
        irisPresentation: root.widgetIris
        regionBrightness: root.regionBrightness
        shown: !root.instrument && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceRadius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : root.widgetCardRadius
        surfaceOpacity: root.backgroundOpacity
        surfaceBorderWidth: root.borderWidth
        surfaceBorderOpacity: root.borderOpacity
        surfaceColor: root.widgetInk
        colorMode: root.colorMode
        surfaceAccent: root.widgetAccent3
        surfaceFill: root.widgetPlateColor
        surfaceUseBlur: root.effectiveBlur
        screenX: root.x
        screenY: root.y
        screenWidth: root.scaledScreenWidth
        screenHeight: root.scaledScreenHeight
    }

    // ── Shape ────────────────────────────────────────────────
    Item {
        anchors.fill: parent
        opacity: root.instrument ? 0 : 1
        visible: opacity > 0
        Behavior on opacity {
            enabled: root.animationsActive
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        Item {
            id: shapeBox
            x: root.pad
            anchors.verticalCenter: parent.verticalCenter
            width: root.shapeSize
            height: root.shapeSize

            // The user's palette: a container role for the shape, its "on" role for what sits inside.
            MaterialShape {
                anchors.fill: parent
                implicitSize: root.shapeSize
                shape: DesktopWidgetShapes.shapeForName(root.shapeName)
                color: root.widgetSemanticContainer(root.widgetPrimaryRole)
            }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.daytime ? "light_mode" : "bedtime"
                fill: 1
                iconSize: Math.round(root.shapeSize * 0.42)
                color: root.widgetSemanticOnContainer(root.widgetPrimaryRole)
            }
        }

        // Three levels at most: an eyebrow, the figure, a detail line. Then the bar.
        ColumnLayout {
            id: info
            x: shapeBox.x + shapeBox.width + Math.round(16 * root.scaleFactor)
            width: root.infoWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.scaleFactor)

            StyledText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                font.weight: Font.DemiBold
                font.capitalization: root.widgetCapitalization
                font.letterSpacing: Math.round(1 * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
            }
            StyledText {
                Layout.fillWidth: true
                text: DateTime.time
                elide: Text.ElideRight
                font.family: root.widgetNumbersFamily
                font.pixelSize: Math.round(34 * root.scaleFactor)
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
                color: root.widgetInk
            }
            StyledText {
                Layout.fillWidth: true
                text: DateTime.date
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.widgetInk, 0.58)
            }
            StyledProgressBar {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(8 * root.scaleFactor)
                valueBarHeight: Math.max(3, Math.round(4 * root.scaleFactor))
                valueBarGap: Math.max(3, Math.round(4 * root.scaleFactor))
                wavy: true
                // The wave holds still: a desktop widget never animates for decoration.
                animateWave: false
                waveFrequency: 4
                value: Math.max(0.02, root.dayFraction)
                highlightColor: root.widgetAccentVisible
                trackColor: ColorUtils.applyAlpha(root.widgetInk, 0.16)
            }
        }
    }

    // ── iNstrument ───────────────────────────────────────────
    // Eyebrow "Channel / Detail", a tabular figure, a scale for a bounded value, labelled fields.
    ColumnLayout {
        id: instrumentBody
        anchors.fill: parent
        anchors.margins: root.instrumentMargin
        opacity: root.instrument ? 1 : 0
        visible: opacity > 0
        spacing: Math.round(6 * root.scaleFactor)
        Behavior on opacity {
            enabled: root.animationsActive
            NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
        }

        InstrumentLabel {
            Layout.fillWidth: true
            text: "__NAME__ / " + root.label
            color: root.widgetAccentVisible
            scaleFactor: root.scaleFactor
            strong: true
        }
        StyledText {
            Layout.fillWidth: true
            text: DateTime.time
            elide: Text.ElideRight
            font.family: root.widgetNumbersFamily
            font.pixelSize: Math.round(40 * root.scaleFactor)
            font.weight: root.widgetEditorial ? Appearance.editorial.titleWeight : Font.Bold
            font.features: ({ "tnum": 1 })
            font.letterSpacing: -1
            color: root.widgetInk
        }
        InstrumentScale {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(10 * root.scaleFactor)
            fraction: root.dayFraction
            divisions: 24
            ink: root.widgetInk
            accent: root.widgetAccentVisible
            animated: root.animationsActive
        }
        InstrumentField {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(2 * root.scaleFactor)
            label: "Date"
            value: DateTime.date
            ink: root.widgetInk
            muted: root.widgetInkMuted
            family: root.widgetNumbersFamily
            scaleFactor: root.scaleFactor
        }
    }

    // ── Quick controls (edit mode): built from the shared pieces, never hand-laid rows ──
    editPopoverContent: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                title: "Style"
                WidgetQuickChoices {
                    current: root.instrument ? "instrument" : "shape"
                    model: [
                        { label: "Shape", icon: "interests", value: "shape" },
                        { label: "Instrument", icon: "avg_pace", value: "instrument" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                visible: !root.instrument
                title: "Shape"
                WidgetShapePicker {
                    Layout.fillWidth: true
                    selectedShape: root.shapeName
                    onShapeSelected: name => root._setOutputValue("shape", name)
                }
            }
        }
    }
}
