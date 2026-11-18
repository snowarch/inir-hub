pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import qs.services
import qs.modules.common.functions
import qs.modules.nihil.style

// NiHiL's name and version, and the way back to how it came.
Item {
    id: root

    required property var host

    property bool armed: false
    property string version: ""

    FileView {
        id: manifest
        path: FileUtils.trimFileProtocol(Qt.resolvedUrl("../plugin.json").toString())
        onLoaded: {
            try {
                root.version = JSON.parse(manifest.text()).version ?? ""
            } catch (error) {
                root.version = ""
            }
        }
    }

    Timer {
        interval: 4000
        running: root.armed
        onTriggered: root.armed = false
    }

    Column {
        anchors.centerIn: parent
        width: Math.min(parent.width - NihilStyle.s(48), NihilStyle.s(460))
        spacing: NihilStyle.s(6)

        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "NiHiL"
            font.pixelSize: NihilStyle.s(72)
            font.weight: Font.Light
        }
        NText {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: root.version.length > 0
            figures: true
            text: Translation.tr("Version %1").arg(root.version)
            color: NihilStyle.inkSoft
        }
        NText {
            width: parent.width
            topPadding: NihilStyle.s(14)
            bottomPadding: NihilStyle.s(18)
            horizontalAlignment: Text.AlignHCenter
            text: Translation.tr("Vertical workspaces, a full overview and glass you shape completely.")
            wrapMode: Text.Wrap
        }
        NButton {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: "undo"
            label: root.armed ? Translation.tr("Press again to restore everything") : Translation.tr("Restore every option")
            lit: root.armed
            onClicked: {
                if (!root.armed) {
                    root.armed = true
                    return
                }
                root.armed = false
                root.host.restoreAll()
            }
        }
    }
}
