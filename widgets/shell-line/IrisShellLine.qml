pragma ComponentBehavior: Bound

// The same command on the Island, first line only. The Island keeps this loaded while its Desktop
// page exists, so the timer follows `visible`: nothing runs while the page is not on screen.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    property string irisSlot: ""
    property var targetScreen

    readonly property string label: String(CustomWidgets.getConfigValue("shell-line", "label", "Uptime"))
    readonly property string command: String(CustomWidgets.getConfigValue("shell-line", "command", ""))
    readonly property int interval: Math.max(5, Number(CustomWidgets.getConfigValue("shell-line", "interval", 60)))
    property string output: ""
    property bool failed: false

    Process {
        id: run
        command: ["sh", "-c", root.command]
        stdout: StdioCollector { id: out }
        onExited: (code, status) => {
            root.failed = code !== 0
            root.output = code === 0 ? out.text.trim().split("\n")[0] : ""
        }
    }
    Timer {
        interval: root.interval * 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible && root.command.length > 0
        onTriggered: if (!run.running) run.running = true
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * IrisStyle.density)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * IrisStyle.density)

        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            role: IrisText.Meta
            text: root.label
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, Math.round(220 * IrisStyle.density))
            elide: Text.ElideRight
            role: IrisText.Body
            font.family: IrisStyle.fontNumbers
            color: root.failed ? IrisStyle.textSecondary : IrisStyle.text
            text: root.failed ? "failed" : (root.output || "…")
        }
    }
}
