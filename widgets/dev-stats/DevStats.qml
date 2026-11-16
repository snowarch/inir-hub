pragma ComponentBehavior: Bound

// The Material face: your contribution graph on the desktop. It extends AbstractBackgroundWidget, which
// gives it placement, dragging, scaling, per-monitor positions, the person's widget design and
// root.widgetInk, the ink that stays readable over whatever wallpaper sits behind it.
//
// The card holds the plate, the account line, the refresh arrow and the words every empty state needs;
// each look below it draws the weeks its own way and is its own file:
//   grid        the weeks as squares, five steps of the accent, the numbers under them
//   instrument  the iNstrument grammar: eyebrow, total, the last two weeks measured, labelled fields
//   weeks       the last twelve weeks as bars, so the rhythm of the work reads at a glance
//   month       this calendar month as a sheet of days, each shaded by what it holds
//   today       today's count in a Material shape, beside the week and the streak
// Every look reads the same numbers, so none of them can disagree with another.

import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets
import "stats.js" as Stats

AbstractBackgroundWidget {
    id: root

    // Must be "custom.<folder name>": it is where this widget's settings live in config.json.
    configEntryName: "custom.dev-stats"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "grid", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 280, y: 200, account: "", discover: true, weeks: 26, showTotals: true, refreshMinutes: 30 })
    // Its ink is read from the wallpaper under it (or from the plate, when there is one).
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 200
    resizeMinHeight: 90

    // ── Look ─────────────────────────────────────────────────
    readonly property string look: {
        if (root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout")
            return "instrument"
        const wanted = String(root._readConfigKey("style") ?? "grid")
        return ["grid", "instrument", "weeks", "month", "today"].indexOf(wanted) >= 0 ? wanted : "grid"
    }
    // iNstrument is borderless by contract; every other look sits on the shared plate.
    readonly property bool instrument: root.look === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property bool showTotals: Boolean(root._readConfigKey("showTotals") ?? true)

    // ── What the looks draw, read once for all of them ───────
    readonly property var reading: DevStatsStore.summary
    readonly property var account: DevStatsStore.account
    readonly property var days: DevStatsStore.days
    readonly property var today: DevStatsStore.fetchedOn
    readonly property bool drawn: DevStatsStore.hasData && root.reading.grid.columns.length > 0
    readonly property int columns: Math.max(1, root.reading.grid.columns.length)

    // A quiet day is the ink at its faintest; busier ones step up through the accent.
    readonly property color quietCell: ColorUtils.applyAlpha(root.widgetInk, 0.09)
    function cellColor(level: int): color {
        switch (level) {
        case 4: return root.widgetAccentVisible
        case 3: return ColorUtils.applyAlpha(root.widgetAccentVisible, 0.72)
        case 2: return ColorUtils.applyAlpha(root.widgetAccentVisible, 0.48)
        case 1: return ColorUtils.applyAlpha(root.widgetAccentVisible, 0.26)
        default: return root.quietCell
        }
    }

    // ── Geometry: everything derives from the scale ──────────
    readonly property int pad: Math.round(16 * root.scaleFactor)
    readonly property int baseGap: Math.max(1, Math.round(2 * root.scaleFactor))
    readonly property int blockGap: Math.round(10 * root.scaleFactor)

    implicitWidth: {
        const cell = Math.round(10 * root.scaleFactor)
        switch (root.look) {
        case "instrument":
            return Math.round(280 * root.scaleFactor)
        case "weeks":
            return root.pad * 2 + 12 * Math.round(15 * root.scaleFactor) + 11 * root.baseGap
        case "month":
            return root.pad * 2 + 7 * Math.round(34 * root.scaleFactor) + 6 * root.baseGap
        case "today":
            return root.pad * 2 + Math.round(104 * root.scaleFactor) + Math.round(18 * root.scaleFactor) + Math.round(168 * root.scaleFactor)
        default:
            return root.pad * 2 + root.columns * cell + (root.columns - 1) * root.baseGap
        }
    }
    implicitHeight: root.pad * 2 + headerLine.implicitHeight + root.blockGap
        + (root.drawn && lookLoader.item ? lookLoader.item.implicitHeight : Math.round(56 * root.scaleFactor))

    // The numbers are minutes old at worst: fetch while the card is on screen, and only then.
    Timer {
        interval: DevStatsStore.refreshInterval
        running: root.visible
        repeat: true
        triggeredOnStart: true
        onTriggered: DevStatsStore.refresh(false)
    }

    // The plate every built-in widget sits on: the person's design, opacity, outline, blur and corners.
    WidgetSurface {
        anchors.fill: parent
        widget: root
        shown: !root.instrument && (root.backgroundOpacity > 0 || root.borderWidth > 0 || root.effectiveBlur)
        surfaceColor: root.widgetInk
        surfaceAccent: root.widgetAccent3
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: 0

        // ── The account, and the one control the card needs ──
        RowLayout {
            id: headerLine
            Layout.fillWidth: true
            spacing: Math.round(6 * root.scaleFactor)

            // The Instrument look carries the account in its own label, so the line steps aside and
            // leaves the refresh arrow where the header keeps it.
            MaterialSymbol {
                Layout.alignment: Qt.AlignVCenter
                visible: !root.instrument
                text: Stats.platformGlyph(root.account)
                iconSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: root.widgetAccentVisible
            }
            StyledText {
                Layout.fillWidth: true
                visible: !root.instrument
                text: root.account
                    ? Stats.platformName(root.account) + " · " + root.account.user
                    : Translation.tr("No account")
                elide: Text.ElideMiddle
                font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
                font.weight: Font.DemiBold
                font.capitalization: root.widgetCapitalization
                color: ColorUtils.applyAlpha(root.widgetInk, 0.72)
            }
            // An invisible item leaves a Qt Quick Layout, so the Instrument look's empty line is held
            // open by a spacer: the refresh arrow stays at the header's right edge.
            Item {
                visible: root.instrument
                Layout.fillWidth: true
            }
            RippleButton {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: Math.round(22 * root.scaleFactor)
                implicitHeight: Math.round(22 * root.scaleFactor)
                buttonRadius: Appearance.rounding.full
                colBackground: "transparent"
                colBackgroundHover: ColorUtils.applyAlpha(root.widgetInk, 0.1)
                colRipple: ColorUtils.applyAlpha(root.widgetInk, 0.16)
                downAction: () => DevStatsStore.refresh(true)
                contentItem: MaterialSymbol {
                    text: "refresh"
                    iconSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                    color: root.widgetInkSubtle
                    rotation: DevStatsStore.busy ? 180 : 0
                    Behavior on rotation {
                        enabled: root.animationsActive && DevStatsStore.busy
                        NumberAnimation { duration: Appearance.animation.elementMoveFast.duration }
                    }
                }
            }
        }

        Loader {
            id: lookLoader
            Layout.fillWidth: true
            Layout.topMargin: root.blockGap
            Layout.preferredHeight: root.drawn && item ? item.implicitHeight : 0
            visible: root.drawn
            sourceComponent: root.look === "instrument" ? instrumentLook
                : root.look === "weeks" ? weeksLook
                : root.look === "month" ? monthLook
                : root.look === "today" ? todayLook
                : gridLook
        }

        // Nothing to draw yet: the card says what it is waiting for, never nothing.
        StyledText {
            Layout.fillWidth: true
            Layout.topMargin: root.blockGap
            visible: !root.drawn
            text: DevStatsStore.emptyWords
            wrapMode: Text.WordWrap
            maximumLineCount: 3
            elide: Text.ElideRight
            font.pixelSize: Math.round(Appearance.font.pixelSize.smaller * root.scaleFactor)
            color: ColorUtils.applyAlpha(root.widgetInk, 0.66)
        }
    }

    Component { id: gridLook; LookGrid { card: root } }
    Component { id: instrumentLook; LookInstrument { card: root } }
    Component { id: weeksLook; LookWeeks { card: root } }
    Component { id: monthLook; LookMonth { card: root } }
    Component { id: todayLook; LookToday { card: root } }

    // ── Quick controls (edit mode) ───────────────────────────
    ownControls: Component {
        ColumnLayout {
            spacing: 14
            WidgetQuickSection {
                title: Translation.tr("Look")
                WidgetQuickChoices {
                    current: root.look
                    model: [
                        { label: Translation.tr("Squares"), icon: "grid_on", value: "grid" },
                        { label: Translation.tr("Instrument"), icon: "avg_pace", value: "instrument" },
                        { label: Translation.tr("Bars"), icon: "bar_chart", value: "weeks" },
                        { label: Translation.tr("Month"), icon: "calendar_month", value: "month" },
                        { label: Translation.tr("Today"), icon: "today", value: "today" }
                    ]
                    onPicked: value => root._setOutputValue("style", value)
                }
            }
            WidgetQuickSection {
                title: Translation.tr("Show")
                WidgetQuickToggle {
                    Layout.fillWidth: true
                    iconName: "numbers"
                    label: Translation.tr("Totals")
                    checked: root.showTotals
                    onToggled: root._setOutputValue("showTotals", !root.showTotals)
                }
            }
        }
    }
}
