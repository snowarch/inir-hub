pragma ComponentBehavior: Bound

// A widget that runs something. Three rules keep it cheap and honest:
//   1. it runs only while someone can see it (visible, and not covered by windows: motionActive);
//   2. one Process, reused; a run never starts while the previous one is still going;
//   3. a failure is shown, with what the command printed, instead of an empty card.
// Running commands is a permission: hub.json declares "process", and the Hub shows it before install.

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.background.widgets

AbstractBackgroundWidget {
    id: root

    configEntryName: "custom.shell-line"
    defaultConfig: ({ placementStrategy: "free", widgetScale: 100, widgetOpacity: 100, colorMode: "auto", dim: 0, x: 260, y: 420 })
    resizableAxes: ({ uniform: "widgetScale" })
    resizeMinWidth: 140
    resizeMinHeight: 56

    readonly property string label: String(root._readConfigKey("label") ?? "Uptime")
    readonly property string command: String(root._readConfigKey("command") ?? "")
    readonly property int interval: Math.max(5, Number(root._readConfigKey("interval") ?? 60))
    readonly property int lines: Math.max(1, Math.min(6, Number(root._readConfigKey("lines") ?? 1)))

    property string output: ""
    property string failure: ""

    readonly property int pad: Math.round(14 * root.scaleFactor)
    implicitWidth: Math.max(Math.round(180 * root.scaleFactor), body.implicitWidth + root.pad * 2)
    implicitHeight: body.implicitHeight + root.pad * 2

    Process {
        id: run
        command: ["sh", "-c", root.command]
        stdout: StdioCollector { id: out }
        stderr: StdioCollector { id: err }
        onExited: (code, status) => {
            if (code === 0) {
                root.output = out.text.trim().split("\n").slice(0, root.lines).join("\n")
                root.failure = ""
            } else {
                root.failure = (err.text.trim().split("\n")[0] || `exited with ${code}`)
            }
        }
    }

    Timer {
        interval: root.interval * 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.motionActive && root.command.length > 0
        onTriggered: if (!run.running) run.running = true
    }
    // A new command runs at once instead of waiting a whole interval.
    onCommandChanged: if (root.visible && root.command.length > 0 && !run.running) run.running = true

    Rectangle {
        anchors.fill: parent
        radius: root.cornerRadiusOverride >= 0 ? root.cornerRadiusOverride : Appearance.rounding.normal
        color: ColorUtils.applyAlpha(root.colText, Math.max(root.backgroundOpacity, 0.06))
        border.width: root.borderWidth
        border.color: ColorUtils.applyAlpha(root.colText, root.borderOpacity)
    }

    ColumnLayout {
        id: body
        anchors.fill: parent
        anchors.margins: root.pad
        spacing: Math.round(4 * root.scaleFactor)

        RowLayout {
            spacing: Math.round(6 * root.scaleFactor)
            MaterialSymbol {
                text: root.failure.length > 0 ? "error" : "terminal"
                iconSize: Math.round(16 * root.scaleFactor)
                color: root.failure.length > 0 ? Appearance.colors.colError : ColorUtils.applyAlpha(root.colText, 0.7)
            }
            StyledText {
                Layout.fillWidth: true
                text: root.label
                elide: Text.ElideRight
                font.pixelSize: Math.round(Appearance.font.pixelSize.small * root.scaleFactor)
                font.weight: Font.DemiBold
                color: ColorUtils.applyAlpha(root.colText, 0.7)
            }
        }

        StyledText {
            Layout.fillWidth: true
            Layout.maximumWidth: Math.round(420 * root.scaleFactor)
            text: root.failure.length > 0 ? root.failure
                : root.command.length === 0 ? "Choose a command in the widget's settings"
                : root.output.length > 0 ? root.output : "…"
            wrapMode: Text.NoWrap
            elide: Text.ElideRight
            maximumLineCount: root.lines
            font.family: Appearance.font.family.monospace
            font.pixelSize: Math.round(Appearance.font.pixelSize.normal * root.scaleFactor)
            color: root.failure.length > 0 ? Appearance.colors.colError : root.colText
        }
    }
}
