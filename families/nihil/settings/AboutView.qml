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

    NWell {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.max(0, (parent.height - height) / 2 - NihilStyle.s(40))
        width: Math.min(parent.width, NihilStyle.s(460))
        height: card.implicitHeight + NihilStyle.s(64)
        radius: NihilStyle.r(22)

        Column {
            id: card
            anchors.centerIn: parent
            width: parent.width - NihilStyle.s(64)
            spacing: NihilStyle.s(6)

            NMark {
                anchors.horizontalCenter: parent.horizontalCenter
                size: NihilStyle.s(56)
            }
            Item { width: 1; height: NihilStyle.s(10) }
            NDisplay {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "NiHiL"
                size: NihilStyle.s(40)
            }
            NLabel {
                anchors.horizontalCenter: parent.horizontalCenter
                text: (root.version.length > 0 ? Translation.tr("Version %1").arg(root.version) + "  ·  " : "") + "GPL-3.0"
            }
            NText {
                width: parent.width
                topPadding: NihilStyle.s(12)
                bottomPadding: NihilStyle.s(18)
                horizontalAlignment: Text.AlignHCenter
                text: Translation.tr("Vertical workspaces, a full overview and glass you shape completely.")
                color: NihilStyle.inkSoft
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
}
