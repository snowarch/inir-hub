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
import qs.modules.shared.background.widgets
import qs.modules.shared.background.widgets.instrument
import "countdown.js" as Countdown

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.countdown"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie9Sided", showProgress: true, showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 240, y: 240 })
    // Its ink is read from the wallpaper under it (or from the plate, when there is one).
    needsColText: true
    resizeMinWidth: 150
    resizeMinHeight: 150

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

    // ── What every face reads ───────────────────────────────
    readonly property string caption: Countdown.caption(root.reading)
    readonly property string dateLine: Countdown.dateLine(root.target, root.dateText)
    readonly property string shortDate: Countdown.shortDate(root.target)
    readonly property string waitedLine: Countdown.waitedLine(root.waited)

    // ── Geometry: a size class draws in its cell (176 small, 368 wide, 368 tall large); an older iNiR without size
    // classes keeps the one card, from the scale ──
    readonly property real k: Math.max(0.4, Math.min(root.width / (root.isSmall ? 176 : 368), root.height / (root.isLarge ? 368 : 176)))
    readonly property real s: root.sized ? root.k : root.scaleFactor
    function px(v: real): int { return Math.round(v * root.s) }
    // Small and large stand the shape over the words, centred; medium sets them side by side.
    readonly property bool stacked: root.sized && (root.isSmall || root.isLarge)
    readonly property int pad: root.px(root.isSmall ? 14 : 16)
    readonly property int shapeSize: root.px(!root.sized ? 100 : root.isSmall ? 92 : root.isLarge ? 176 : 120)
    readonly property int instrumentMargin: root.px(14)
    // Only an older iNiR without size classes reads these; a class's cell sets the box (and `k` reads the box).
    implicitWidth: root.sized ? root.footprintWidth : Math.round((root.instrument ? 270 : 336) * root.scaleFactor)
    implicitHeight: root.sized ? root.footprintHeight : Math.round((root.instrument ? 150 : 132) * root.scaleFactor)

    // The plate every built-in widget sits on: the user's design, opacity, outline, blur and corners.
    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && !root.familyFaced && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    // ── Shape ────────────────────────────────────────────────
    // Built only while it is the face shown: under a family's design the family's face draws instead.
    Loader {
        anchors.fill: parent
        active: !root.instrument && !root.familyFaced
        sourceComponent: Item {
            id: face

            Item {
                id: shapeBox
                x: root.stacked ? Math.round((face.width - width) / 2) : root.pad + (root.sized ? root.px(4) : 0)
                y: root.stacked ? root.px(root.isSmall ? 14 : 28) : Math.round((face.height - height) / 2)
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
                    minimumPixelSize: root.px(12)
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
                id: info
                readonly property int align: root.stacked ? Text.AlignHCenter : Text.AlignLeft
                x: root.stacked ? root.pad : shapeBox.x + shapeBox.width + root.px(root.sized ? 20 : 16)
                y: root.stacked ? shapeBox.y + shapeBox.height + root.px(root.isSmall ? 8 : 18)
                    : Math.round((face.height - height) / 2)
                width: face.width - x - root.pad
                spacing: root.px(2)

                // Eyebrow: the accent glyph and what it counts down to.
                RowLayout {
                    Layout.fillWidth: !root.stacked
                    Layout.maximumWidth: info.width
                    Layout.alignment: root.stacked ? Qt.AlignHCenter : Qt.AlignLeft
                    spacing: root.px(6)
                    MaterialSymbol {
                        text: "hourglass_bottom"
                        fill: 1
                        iconSize: root.px(Appearance.font.pixelSize.small)
                        color: root.widgetAccent3Visible
                    }
                    StyledText {
                        Layout.fillWidth: !root.stacked
                        Layout.maximumWidth: info.width - root.px(Appearance.font.pixelSize.small + 6)
                        text: root.label
                        elide: Text.ElideRight
                        font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
                        font.weight: Font.DemiBold
                        font.capitalization: root.widgetCapitalization
                        font.letterSpacing: root.isSmall ? 0 : root.px(1)
                        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
                    }
                }

                StyledText {
                    Layout.fillWidth: true
                    Layout.topMargin: root.px(2)
                    horizontalAlignment: info.align
                    text: root.caption
                    // "left today" in a small card shrinks a little before it would be cut.
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: root.px(12)
                    font.family: root.widgetTitleFamily
                    font.pixelSize: root.px((root.isSmall ? Appearance.font.pixelSize.larger : Appearance.font.pixelSize.huge)
                        * root.widgetTitleScale * (root.isLarge ? 1.3 : 1))
                    font.weight: root.widgetTitleWeight
                    font.letterSpacing: root.widgetTitleTracking
                    color: root.widgetInk
                }

                StyledText {
                    Layout.fillWidth: true
                    visible: !root.isSmall
                    horizontalAlignment: info.align
                    text: root.reading.valid ? root.dateLine : "Choose one in its settings"
                    // The hint may wrap (it is the only line under the title then); the date never needs to.
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    font.pixelSize: root.px(Appearance.font.pixelSize.small)
                    color: ColorUtils.applyAlpha(root.widgetInk, 0.58)
                }

                // How much of the wait has gone by, since the day the date was set.
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: root.px(root.isLarge ? 14 : 8)
                    visible: root.barShown && !root.isSmall
                    spacing: root.px(8)

                    StyledProgressBar {
                        Layout.fillWidth: true
                        valueBarHeight: Math.max(3, root.px(4))
                        valueBarGap: Math.max(3, root.px(4))
                        wavy: true
                        // The wave holds still: a desktop widget never animates for decoration.
                        animateWave: false
                        waveFrequency: root.isLarge ? 6 : 4
                        value: Math.max(0.02, root.waited)
                        highlightColor: root.widgetAccentVisible
                        trackColor: ColorUtils.applyAlpha(root.widgetInk, 0.16)
                    }
                    StyledText {
                        text: Math.round(root.waited * 100) + "%"
                        font.family: root.widgetNumbersFamily
                        font.pixelSize: root.px(Appearance.font.pixelSize.smaller)
                        font.weight: Font.DemiBold
                        font.features: ({ "tnum": 1 })
                        color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
                    }
                }
            }
        }
    }

    // ── iNstrument ───────────────────────────────────────────
    // A countdown is a bounded wait, so it reads on a linear scale, never on a fake dial. Small drops the fields.
    Loader {
        anchors.fill: parent
        anchors.margins: root.instrumentMargin
        active: root.instrument && !root.familyFaced
        sourceComponent: ColumnLayout {
            id: instrumentBody
            spacing: root.px(6)

            InstrumentLabel {
                Layout.fillWidth: true
                text: "Countdown / " + root.label
                color: root.widgetAccentVisible
                scaleFactor: root.s
                strong: true
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: root.px(8)
                StyledText {
                    Layout.maximumWidth: instrumentBody.width * 0.62
                    text: root.reading.valid ? (root.arrived ? "Today" : root.reading.figure) : "--"
                    fontSizeMode: Text.HorizontalFit
                    minimumPixelSize: root.px(20)
                    font.family: root.widgetNumbersFamily
                    font.pixelSize: root.px(root.isLarge ? 72 : 44)
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
                    scaleFactor: root.s
                    size: 11
                    strong: true
                }
            }

            InstrumentScale {
                Layout.fillWidth: true
                Layout.preferredHeight: root.px(10)
                visible: root.barShown
                fraction: root.waited
                divisions: root.isSmall ? 16 : 32
                ink: root.widgetInk
                accent: root.widgetAccentVisible
                animated: root.animationsActive
            }

            Item { Layout.fillHeight: true; visible: root.isLarge }

            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: root.px(2)
                visible: !root.isSmall
                spacing: root.px(14)
                InstrumentField {
                    Layout.fillWidth: true
                    label: "Date"
                    value: root.target ? root.dateLine : "Not set"
                    ink: root.widgetInk
                    muted: root.widgetInkMuted
                    family: root.widgetNumbersFamily
                    scaleFactor: root.s
                }
                InstrumentField {
                    Layout.preferredWidth: root.px(70)
                    visible: root.barShown
                    label: "Waited"
                    value: Math.round(root.waited * 100) + "%"
                    ink: root.widgetInk
                    muted: root.widgetInkMuted
                    family: root.widgetNumbersFamily
                    scaleFactor: root.s
                }
            }
        }
    }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
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
