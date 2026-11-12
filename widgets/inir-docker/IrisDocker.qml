pragma ComponentBehavior: Bound

// The iRiS face: one compact line on the Island's Desktop page. The full
// controls live on the Material desktop card; this face answers "is Docker
// healthy?" at a glance.

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components
import "docker.js" as Docker

Item {
    id: root

    property string irisSlot: ""
    property var targetScreen

    readonly property int refreshSeconds: Math.max(1, Math.min(60,
        Number(CustomWidgets.getConfigValue("inir-docker", "refreshSeconds", 3))))
    property var snapshot: null
    property string error: ""

    readonly property var containers: (root.snapshot && root.snapshot.containers) ? root.snapshot.containers : []
    readonly property int running: root.containers.filter(container => container.status === "running").length
    readonly property int total: root.containers.length
    readonly property bool available: Boolean(root.snapshot && root.snapshot.dockerAvailable)

    Process {
        id: snapshotProc
        command: Docker.snapshotCommand
        stdout: StdioCollector {
            id: snapshotOut
            waitForEnd: true
        }
        stderr: StdioCollector {
            id: snapshotErr
            waitForEnd: true
        }
        onExited: (code, status) => {
            if (code === 0) {
                try {
                    const next = Docker.parseSnapshot(snapshotOut.text)
                    if (next && next.dockerAvailable) {
                        root.snapshot = next
                        root.error = ""
                    } else {
                        root.error = Translation.tr("offline")
                    }
                } catch (e) {
                    root.error = Translation.tr("unreadable")
                }
            } else {
                root.error = Translation.tr("offline")
            }
        }
    }

    Timer {
        interval: root.refreshSeconds * 1000
        repeat: true
        triggeredOnStart: true
        running: root.visible
        onTriggered: if (!snapshotProc.running) snapshotProc.running = true
    }

    implicitWidth: row.implicitWidth
    implicitHeight: Math.round(28 * IrisStyle.density)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Math.round(6 * IrisStyle.density)

        MaterialSymbol {
            anchors.verticalCenter: parent.verticalCenter
            text: "deployed_code"
            fill: 1
            iconSize: Math.round(16 * IrisStyle.density)
            color: root.error.length > 0 ? IrisStyle.textSecondary : IrisStyle.accent
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            role: IrisText.Meta
            text: "Docker"
        }
        IrisText {
            anchors.verticalCenter: parent.verticalCenter
            role: IrisText.Body
            font.family: IrisStyle.fontNumbers
            color: root.error.length > 0 ? IrisStyle.textSecondary : IrisStyle.text
            text: root.error.length > 0 ? root.error : (root.available ? root.running + "/" + root.total : "…")
        }
    }
}
