pragma ComponentBehavior: Bound

// A widget that runs something. Three rules keep it cheap and honest:
//   1. it runs only while someone can see it (visible, and not covered by windows: motionActive);
//   2. one Process, reused; a run never starts while the previous one is still going;
//   3. a failure is shown, with what the command printed, instead of an empty card.
// Running commands is a permission: hub.json declares "process", and the Hub shows it before install.
//
// What the command prints decides how it is drawn (shellline.js):
//   "62%"            a figure and a wavy bar        (df, battery, volume)
//   "14 updates"     a large figure and its unit     (counts, temperatures)
//   anything else    up to `lines` lines, each one elided at the card's edge

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets
import qs.modules.background.widgets.instrument
import "shellline.js" as ShellLine

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.shell-line"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, style: "shape", shape: "Cookie4Sided", showBackground: true, backgroundOpacity: 0.16, borderWidth: 1, borderOpacity: 0.2, cornerRadius: -1, useBlur: false, x: 260, y: 420 })
    // Its ink is read from the wallpaper under it (or from the plate, when there is one).
    needsColText: true
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 200
    resizeMinHeight: 72

    // ── Look ─────────────────────────────────────────────────
    // The user's global widget design wins: under iNstrument or Readout this draws that grammar.
    readonly property bool instrument: root.widgetSharedDesign === "instrument" || root.widgetSharedDesign === "readout"
        || String(root._readConfigKey("style") ?? "shape") === "instrument"
    widgetSurfaceEnabled: !root.instrument
    readonly property string shapeName: String(root._readConfigKey("shape") ?? "Cookie4Sided")

    // ── What it runs ─────────────────────────────────────────
    readonly property string label: String(root._readConfigKey("label") ?? "Home folder")
    readonly property string icon: String(root._readConfigKey("icon") ?? "hard_drive")
    readonly property string command: String(root._readConfigKey("command") ?? "")
    readonly property int interval: Math.max(5, Number(root._readConfigKey("interval") ?? 300))
    readonly property int lines: Math.max(1, Math.min(6, Number(root._readConfigKey("lines") ?? 3)))

    // The command's whole answer; reading it again for a new `lines` needs no rerun.
    property string answer: ""
    property string failure: ""
    property var lastRun: null
    readonly property var reading: ShellLine.read(root.answer, root.lines)
    readonly property bool waiting: root.command.length > 0 && root.lastRun === null && root.failure.length === 0
    readonly property bool failed: root.failure.length > 0

    Process {
        id: run
        command: ["sh", "-c", root.command]
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onRunningChanged: if (running && root.animationsActive) pulse.restart()
        onExited: (code, status) => {
            if (code === 0) {
                root.answer = out.text.trim()
                root.failure = ""
            } else {
                root.failure = err.text.trim().split("\n")[0] || `It stopped with code ${code}`
            }
            root.lastRun = new Date()
        }
    }

    Timer {
        interval: root.interval * 1000
        repeat: true
        triggeredOnStart: true
        // The first run happens even behind windows, so a card added there is never stuck on "Running…".
        running: root.visible && root.command.length > 0 && (root.motionActive || root.lastRun === null)
        onTriggered: if (!run.running) run.running = true
    }
    // A new command runs at once instead of waiting a whole interval. One tick later, so the
    // Process has taken the new command, and after the old run ends if one is still going.
    onCommandChanged: rerun.restart()
    Timer {
        id: rerun
        interval: run.running ? 200 : 0
        onTriggered: {
            if (run.running)
                rerun.restart()
            else if (root.visible && root.command.length > 0)
                run.running = true
        }
    }
    // Each run gives the shape one short spring, so a refresh is felt without anything looping.
    Timer {
        id: pulse
        interval: 520
    }

    // ── Colour roles (the user's widget palette and the theme's error role, never literals) ──
    readonly property color shapeFill: root.failed ? Appearance.colors.colErrorContainer
        : root.command.length === 0 ? ColorUtils.applyAlpha(root.widgetInk, 0.14)
        : root.widgetSemanticContainer(root.widgetPrimaryRole)
    readonly property color shapeInk: root.failed ? Appearance.colors.colOnErrorContainer
        : root.command.length === 0 ? root.widgetInk
        : root.widgetSemanticOnContainer(root.widgetPrimaryRole)
    readonly property color mutedInk: ColorUtils.applyAlpha(root.widgetInk, 0.62)

    // ── Geometry ─────────────────────────────────────────────
    readonly property int pad: Math.round(16 * root.scaleFactor)
    readonly property int shapeSize: Math.round(64 * root.scaleFactor)
    readonly property int gap: Math.round(14 * root.scaleFactor)
    readonly property int infoWidth: Math.round(196 * root.scaleFactor)
    readonly property int instrumentMargin: Math.round(14 * root.scaleFactor)
    implicitWidth: root.instrument ? Math.round(272 * root.scaleFactor)
        : root.pad * 2 + root.shapeSize + root.gap + root.infoWidth
    implicitHeight: root.instrument ? instrumentBody.implicitHeight + root.instrumentMargin * 2
        : Math.max(root.shapeSize, info.implicitHeight) + root.pad * 2

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
            y: root.pad
            width: root.shapeSize
            height: root.shapeSize

            MaterialShape {
                anchors.fill: parent
                implicitSize: root.shapeSize
                shape: DesktopWidgetShapes.shapeForName(root.failed ? "SoftBoom" : pulse.running ? "SoftBurst" : root.shapeName)
                color: root.shapeFill
            }
            MaterialSymbol {
                anchors.centerIn: parent
                text: root.failed ? "error" : root.command.length === 0 ? "terminal" : root.icon
                fill: 1
                iconSize: Math.round(root.shapeSize * 0.44)
                color: root.shapeInk
            }
        }

        ColumnLayout {
            id: info
            x: shapeBox.x + shapeBox.width + root.gap
            y: root.pad + Math.max(0, Math.round((Math.max(root.shapeSize, implicitHeight) - implicitHeight) / 2))
            width: root.infoWidth
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

            // Percent and number: the figure, its unit on the baseline.
            RowLayout {
                Layout.fillWidth: true
                visible: !root.failed && (root.reading.kind === "percent" || root.reading.kind === "number")
                spacing: Math.round(6 * root.scaleFactor)
                StyledText {
                    Layout.maximumWidth: root.infoWidth
                    text: root.reading.figure
                    elide: Text.ElideRight
                    font.family: root.widgetNumbersFamily
                    font.pixelSize: Math.round(34 * root.scaleFactor)
                    font.weight: Font.Bold
                    font.features: ({ "tnum": 1 })
                    color: root.widgetInk
                }
                StyledText {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBaseline
                    visible: text.length > 0
                    text: root.reading.unit
                    elide: Text.ElideRight
                    font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                    color: root.mutedInk
                }
            }

            StyledProgressBar {
                Layout.fillWidth: true
                Layout.topMargin: Math.round(4 * root.scaleFactor)
                visible: !root.failed && root.reading.kind === "percent"
                valueBarHeight: Math.max(3, Math.round(4 * root.scaleFactor))
                valueBarGap: Math.max(3, Math.round(4 * root.scaleFactor))
                wavy: true
                animateWave: false
                waveFrequency: 4
                value: Math.max(0.02, root.reading.fraction)
                highlightColor: root.reading.fraction >= 0.9 ? root.widgetSemanticForeground(root.widgetSignalRole) : root.widgetAccentVisible
                trackColor: ColorUtils.applyAlpha(root.widgetInk, 0.16)
            }

            // Text: one row per line, each elided at the card's edge, never running past it.
            Repeater {
                model: !root.failed && root.reading.kind === "text" ? root.reading.lines : []
                StyledText {
                    required property string modelData
                    Layout.fillWidth: true
                    text: modelData
                    elide: Text.ElideRight
                    wrapMode: Text.NoWrap
                    font.family: Appearance.font.family.monospace
                    font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                    color: root.widgetInk
                }
            }

            // Not set, failed, or the first run still going: a sentence, wrapped, never a blank card.
            StyledText {
                Layout.fillWidth: true
                visible: root.failed || root.command.length === 0 || root.waiting || root.reading.kind === "empty"
                text: root.failed ? root.failure
                    : root.command.length === 0 ? "Choose a command in its settings"
                    : root.waiting ? "Running…" : "It printed nothing"
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                elide: Text.ElideRight
                font.family: root.failed ? Appearance.font.family.monospace : root.widgetBodyFamily
                font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
                color: root.failed ? root.widgetInk : root.mutedInk
            }
        }
    }

    // ── iNstrument ───────────────────────────────────────────
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
            text: "Command / " + root.label
            color: root.failed ? root.widgetSemanticForeground(root.widgetSignalRole) : root.widgetAccentVisible
            scaleFactor: root.scaleFactor
            strong: true
        }

        RowLayout {
            Layout.fillWidth: true
            visible: !root.failed && (root.reading.kind === "percent" || root.reading.kind === "number")
            spacing: Math.round(8 * root.scaleFactor)
            StyledText {
                Layout.maximumWidth: instrumentBody.width * 0.7
                text: root.reading.figure
                elide: Text.ElideRight
                font.family: root.widgetNumbersFamily
                font.pixelSize: Math.round(40 * root.scaleFactor)
                font.weight: root.widgetEditorial ? Appearance.editorial.titleWeight : Font.Bold
                font.features: ({ "tnum": 1 })
                font.letterSpacing: -1
                color: root.widgetInk
            }
            InstrumentLabel {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignBaseline
                text: root.reading.unit
                color: root.widgetInkMuted
                scaleFactor: root.scaleFactor
                size: 11
                strong: true
            }
        }

        InstrumentScale {
            Layout.fillWidth: true
            Layout.preferredHeight: Math.round(10 * root.scaleFactor)
            visible: !root.failed && root.reading.kind === "percent"
            fraction: root.reading.fraction
            divisions: 32
            ink: root.widgetInk
            accent: root.reading.fraction >= 0.9 ? root.widgetSemanticForeground(root.widgetSignalRole) : root.widgetAccentVisible
            animated: root.animationsActive
        }

        Repeater {
            model: !root.failed && root.reading.kind === "text" ? root.reading.lines : []
            StyledText {
                required property string modelData
                Layout.fillWidth: true
                text: modelData
                elide: Text.ElideRight
                wrapMode: Text.NoWrap
                font.family: Appearance.font.family.monospace
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                color: root.widgetInk
            }
        }

        StyledText {
            Layout.fillWidth: true
            visible: root.failed || root.command.length === 0 || root.waiting || root.reading.kind === "empty"
            text: root.failed ? root.failure
                : root.command.length === 0 ? "Choose a command in its settings"
                : root.waiting ? "Running…" : "It printed nothing"
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
            font.family: Appearance.font.family.monospace
            font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
            color: root.failed ? root.widgetInk : root.widgetInkMuted
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: Math.round(2 * root.scaleFactor)
            spacing: Math.round(14 * root.scaleFactor)
            InstrumentField {
                Layout.fillWidth: true
                label: "Updated"
                value: root.lastRun ? Qt.locale().toString(root.lastRun, "HH:mm") : ""
                ink: root.widgetInk
                muted: root.widgetInkMuted
                family: root.widgetNumbersFamily
                scaleFactor: root.scaleFactor
            }
            InstrumentField {
                Layout.fillWidth: true
                label: "Every"
                value: ShellLine.every(root.interval)
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
        }
    }
}
