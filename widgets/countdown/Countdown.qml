pragma ComponentBehavior: Bound

// The Material face. It extends AbstractBackgroundWidget, which gives it placement, dragging, scaling,
// per-monitor positions, the user's widget design and the ink (root.widgetInk) that stays readable over
// whatever wallpaper sits behind it.
//
// Two looks, like the built-in widgets:
//   Shape       the figure inside a Material shape the user picks; the shape morphs when the day
//               arrives (a burst) and when there is no date yet. A wavy bar measures the wait.
//   Instrument  the iNstrument grammar (eyebrow "Channel / Detail", tabular figure, a measured scale,
//               labelled fields). It is also what this widget draws whenever the user's global widget
//               design is iNstrument or Readout, so it never sticks out among the built-ins.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets
import qs.modules.background.widgets.instrument
import "countdown.js" as Countdown

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.countdown"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie9Sided", showProgress: true, showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240 })
    // Its ink is read from the wallpaper under it (or from the plate, when there is one).
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 220
    resizeMinHeight: 100

    // ── Look ─────────────────────────────────────────────────
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    // iNstrument is borderless by contract; the shape look sits on the shared plate.
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie9Sided")
    readonly property bool showProgress: Boolean(root._readConfigKey("showProgress") ?? true)

    // ── What it counts ───────────────────────────────────────
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
    readonly property bool arrived: root.reading.valid && root.reading.past && root.reading.unit.length === 0
    readonly property bool over: root.reading.valid && root.reading.past && !root.arrived
    readonly property real waited: Countdown.progress(Countdown.parse(String(root._readConfigKey("since") ?? "")), root.target, clock.date)
    readonly property bool barShown: root.showProgress && root.waited >= 0 && root.reading.valid && !root.reading.past

    // The bar measures the wait from the day the date was set. That day is stored once per date, in
    // two keys the settings page does not show ("since" and the date it belongs to).
    readonly property bool _needsSince: Config.ready && root.target !== null
        && String(root._readConfigKey("sinceFor") ?? "") !== root.dateText
    on_NeedsSinceChanged: if (root._needsSince) stampSince.restart()
    Component.onCompleted: if (root._needsSince) stampSince.restart()
    Timer {
        id: stampSince
        interval: 0
        onTriggered: if (root._needsSince) root._setOutputValues({ since: Countdown.isoDay(new Date()), sinceFor: root.dateText })
    }

    // ── Colour roles (the user's widget palette, never literals) ──
    readonly property color shapeFill: root.arrived ? root.widgetSemanticContainer(root.widgetTertiaryRole)
        : root.over ? root.widgetSemanticContainer(root.widgetSecondaryRole)
        : root.reading.valid ? root.widgetSemanticContainer(root.widgetPrimaryRole)
        : ColorUtils.applyAlpha(root.widgetInk, 0.14)
    readonly property color shapeInk: root.arrived ? root.widgetSemanticOnContainer(root.widgetTertiaryRole)
        : root.over ? root.widgetSemanticOnContainer(root.widgetSecondaryRole)
        : root.reading.valid ? root.widgetSemanticOnContainer(root.widgetPrimaryRole)
        : root.widgetInk

    // ── Geometry: everything derives from the scale ──────────
    readonly property int pad: Math.round(16 * root.scaleFactor)
    readonly property int shapeSize: Math.round(100 * root.scaleFactor)
    readonly property int infoWidth: Math.round(172 * root.scaleFactor)
    readonly property int instrumentMargin: Math.round(14 * root.scaleFactor)
    implicitWidth: root.instrument ? Math.round(270 * root.scaleFactor)
        : root.pad * 2 + root.shapeSize + Math.round(16 * root.scaleFactor) + root.infoWidth
    implicitHeight: root.instrument ? instrumentBody.implicitHeight + root.instrumentMargin * 2
        : root.shapeSize + root.pad * 2

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

            // Changing the shape morphs it (ShapeCanvas springs between the two outlines).
            MaterialShape {
                anchors.fill: parent
                implicitSize: root.shapeSize
                shape: DesktopWidgetShapes.shapeForName(root.arrived ? "SoftBurst" : root.reading.valid ? root.shapeName : "Cookie4Sided")
                color: root.shapeFill
            }

            StyledText {
                anchors.centerIn: parent
                width: Math.round(root.shapeSize * 0.7)
                height: Math.round(root.shapeSize * 0.5)
                visible: root.reading.valid && !root.arrived
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                // "83" fills the shape; "11h 40m" shrinks to fit it instead of spilling out.
                fontSizeMode: Text.Fit
                minimumPixelSize: Math.round(12 * root.scaleFactor)
                text: root.reading.figure
                color: root.shapeInk
                font.family: root.widgetNumbersFamily
                font.pixelSize: Math.round(root.shapeSize * 0.42)
                font.weight: Font.Bold
                font.features: ({ "tnum": 1 })
            }

            MaterialSymbol {
                anchors.centerIn: parent
                visible: !root.reading.valid || root.arrived
                text: root.arrived ? "celebration" : "edit_calendar"
                fill: 1
                iconSize: Math.round(root.shapeSize * 0.4)
                color: root.shapeInk
            }
        }

        ColumnLayout {
            x: shapeBox.x + shapeBox.width + Math.round(16 * root.scaleFactor)
            width: root.infoWidth
            anchors.verticalCenter: parent.verticalCenter
            spacing: Math.round(2 * root.scaleFactor)

            // Eyebrow: the accent glyph and what it counts down to.
            RowLayout {
                Layout.fillWidth: true
                spacing: Math.round(6 * root.scaleFactor)
                MaterialSymbol {
                    text: "hourglass_bottom"
                    fill: 1
                    iconSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                    color: root.widgetAccent3Visible
                }
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
            }

            StyledText {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(2 * root.scaleFactor)
                text: Countdown.caption(root.reading)
                elide: Text.ElideRight
                font.family: root.widgetTitleFamily
                font.pixelSize: Math.round(Appearance.font.pixelSize.huge * root.widgetTitleScale * root.scaleFactor)
                font.weight: root.widgetTitleWeight
                font.letterSpacing: root.widgetTitleTracking
                color: root.widgetInk
            }

            StyledText {
                Layout.fillWidth: true
                text: root.reading.valid ? Countdown.dateLine(root.target, root.dateText) : "Choose one in its settings"
                // The hint may wrap (it is the only line under the title then); the date never needs to.
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: ColorUtils.applyAlpha(root.widgetInk, 0.58)
            }

            // How much of the wait has gone by, since the day the date was set.
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(8 * root.scaleFactor)
                visible: root.barShown
                spacing: Math.round(8 * root.scaleFactor)

                StyledProgressBar {
                    Layout.fillWidth: true
                    valueBarHeight: Math.max(3, Math.round(4 * root.scaleFactor))
                    valueBarGap: Math.max(3, Math.round(4 * root.scaleFactor))
                    wavy: true
                    // The wave holds still: a desktop widget never animates for decoration.
                    animateWave: false
                    waveFrequency: 4
                    value: Math.max(0.02, root.waited)
                    highlightColor: root.widgetAccentVisible
                    trackColor: ColorUtils.applyAlpha(root.widgetInk, 0.16)
                }
                StyledText {
                    text: Math.round(root.waited * 100) + "%"
                    font.family: root.widgetNumbersFamily
                    font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                    font.weight: Font.DemiBold
                    font.features: ({ "tnum": 1 })
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
                }
            }
        }
    }

    // ── iNstrument ───────────────────────────────────────────
    // A countdown is a bounded wait, so it reads on a linear scale, never on a fake dial.
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
            text: "Countdown / " + root.label
            color: root.widgetAccentVisible
            scaleFactor: root.scaleFactor
            strong: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: Math.round(8 * root.scaleFactor)
            StyledText {
                Layout.maximumWidth: instrumentBody.width * 0.62
                text: root.reading.valid ? (root.arrived ? "Today" : root.reading.figure) : "--"
                elide: Text.ElideRight
                font.family: root.widgetNumbersFamily
                font.pixelSize: Math.round(44 * root.scaleFactor)
                font.weight: root.widgetEditorial ? Appearance.editorial.titleWeight : Font.Bold
                font.features: ({ "tnum": 1 })
                font.letterSpacing: -1
                color: root.arrived ? root.widgetAccentVisible : root.widgetInk
            }
            InstrumentLabel {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
                visible: root.reading.valid && !root.arrived
                text: root.reading.past ? root.reading.unit : root.reading.unit === "left" ? "left today" : root.reading.unit + " left"
                color: root.widgetInkMuted
                scaleFactor: root.scaleFactor
                size: 11
                strong: true
            }
        }

        InstrumentScale {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(10 * root.scaleFactor)
            visible: root.barShown
            fraction: root.waited
            divisions: 32
            ink: root.widgetInk
            accent: root.widgetAccentVisible
            animated: root.animationsActive
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(2 * root.scaleFactor)
            spacing: Math.round(14 * root.scaleFactor)
            InstrumentField {
                Layout.fillWidth: true
                label: "Date"
                value: root.target ? Countdown.dateLine(root.target, root.dateText) : "Not set"
                ink: root.widgetInk
                muted: root.widgetInkMuted
                family: root.widgetNumbersFamily
                scaleFactor: root.scaleFactor
            }
            InstrumentField {
                Layout.preferredWidth: Math.round(70 * root.scaleFactor)
                visible: root.barShown
                label: "Waited"
                value: Math.round(root.waited * 100) + "%"
                ink: root.widgetInk
                muted: root.widgetInkMuted
                family: root.widgetNumbersFamily
                scaleFactor: root.scaleFactor
            }
        }
    }

    // ── Quick controls (edit mode) ───────────────────────────
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
            WidgetQuickSection {
                title: "Show"
                WidgetQuickToggle {
                    Layout.fillWidth: true
                    iconName: "linear_scale"
                    label: "Wait bar"
                    checked: root.showProgress
                    onToggled: root._setOutputValue("showProgress", !root.showProgress)
                }
            }
        }
    }
}
