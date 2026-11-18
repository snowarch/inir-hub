pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.services
import qs.modules.nihil.style

// The whole shell, one tap to change it: every family on this machine, the one in use lit.
Column {
    id: root

    spacing: NihilStyle.s(4)

    Repeater {
        model: Plugins.families
        Item {
            id: line
            required property var modelData
            readonly property var manifest: Plugins.manifests[line.modelData] ?? ({})
            readonly property bool inUse: Plugins.active === line.modelData
            width: root.width
            height: NihilStyle.s(58)
            NIcon {
                id: mark
                anchors.verticalCenter: parent.verticalCenter
                text: String(line.manifest.icon ?? "dashboard")
                size: NihilStyle.s(24)
                color: line.inUse ? NihilStyle.accent : NihilStyle.ink
            }
            Column {
                anchors.left: mark.right
                anchors.leftMargin: NihilStyle.s(12)
                anchors.right: use.left
                anchors.rightMargin: NihilStyle.s(10)
                anchors.verticalCenter: parent.verticalCenter
                NText {
                    width: parent.width
                    text: String(line.manifest.name ?? line.modelData)
                    font.weight: Font.Medium
                }
                NText {
                    width: parent.width
                    text: String(line.manifest.tagline ?? line.manifest.summary ?? "")
                    font.pixelSize: NihilStyle.textSmall
                    color: NihilStyle.inkSoft
                }
            }
            NKey {
                id: use
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: NihilStyle.s(92)
                height: NihilStyle.s(38)
                lit: line.inUse
                label: line.inUse ? Translation.tr("In use") : Translation.tr("Use")
                onClicked: if (!line.inUse) Quickshell.execDetached([Quickshell.shellPath("scripts/inir"), "panelFamily", "set", line.modelData])
            }
        }
    }
}
