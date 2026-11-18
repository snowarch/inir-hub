pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
import qs.modules.nihil.style

// What is running here, and whether there is something newer.
Column {
    id: root

    readonly property string state: ShellUpdates.isChecking ? "checking"
        : ShellUpdates.hasUpdate ? "update"
        : ShellUpdates.lastError.length > 0 ? "failed"
        : ShellUpdates.managedExternally ? "packaged"
        : ShellUpdates.waitingForNetwork ? "offline"
        : "current"
    readonly property string shellVersion: ShellUpdates.localVersion.length > 0 ? ShellUpdates.localVersion : shipped.text().trim()

    spacing: NihilStyle.s(12)
    Component.onCompleted: ShellUpdates.check()

    FileView { id: shipped; path: Quickshell.shellPath("VERSION"); blockLoading: true }

    Row {
        spacing: NihilStyle.s(28)
        Repeater {
            model: [
                { name: "iNiR", value: root.shellVersion },
                { name: "NiHiL", value: String(Plugins.manifests?.nihil?.version ?? "") }
            ]
            Column {
                id: part
                required property var modelData
                spacing: NihilStyle.s(6)
                NText {
                    mono: true
                    text: part.modelData.name.toUpperCase()
                    font.pixelSize: NihilStyle.textSmall
                    font.weight: Font.DemiBold
                }
                DotText {
                    text: part.modelData.value.length > 0 ? part.modelData.value.toUpperCase() : "-"
                    dot: NihilStyle.s(3)
                    fitWidth: Math.max(NihilStyle.s(120), root.width / 2 - NihilStyle.s(28))
                }
            }
        }
    }

    Row {
        spacing: NihilStyle.s(10)
        NSpinner {
            visible: root.state === "checking"
            anchors.verticalCenter: parent.verticalCenter
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.state === "checking" ? Translation.tr("Looking for updates")
                : root.state === "update" ? Translation.tr("A new version is ready")
                : root.state === "failed" ? Translation.tr("Could not look for updates")
                : root.state === "packaged" ? Translation.tr("Your package manager keeps iNiR current")
                : root.state === "offline" ? Translation.tr("Waiting for the network")
                : Translation.tr("You are up to date")
            color: NihilStyle.inkSoft
        }
    }

    Row {
        spacing: NihilStyle.s(8)
        NKey {
            width: NihilStyle.s(136)
            height: NihilStyle.s(38)
            lit: root.state === "update"
            glyph: root.state === "update" ? "download" : "refresh"
            label: root.state === "update" ? Translation.tr("Update") : Translation.tr("Check again")
            onClicked: root.state === "update" ? ShellUpdates.performUpdate() : ShellUpdates.check()
        }
        NKey {
            width: NihilStyle.s(136)
            height: NihilStyle.s(38)
            glyph: "menu_book"
            label: Translation.tr("Read the docs")
            onClicked: Qt.openUrlExternally("https://inir.space/docs")
        }
    }
}
