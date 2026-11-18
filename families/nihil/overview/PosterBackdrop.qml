pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// The poster the compositor's overview stands on. Niri draws this surface in its backdrop, behind the workspaces it
// shrinks, so the live windows float in front of the type the way an object stands before a poster's title. The field
// and the giant workspace name are this surface's only content; nothing here takes input.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData
        readonly property string output: root.modelData.name
        readonly property var options: Config.options?.nihil?.overview
        readonly property string subject: root.options?.poster ?? "workspace"
        readonly property var workspaces: NihilState.workspacesOn(root.output)
        readonly property int at: NihilState.activeIndexOn(root.output)
        readonly property var workspace: root.workspaces[root.at]
        // The workspace's name, else what lives there, else its number: a word wide enough to show past the
        // workspace standing in front of it.
        readonly property string title: {
            if (root.subject === "clock") return DateTime.time
            const name = String(root.workspace?.name ?? "")
            if (name.length > 0) return name
            const wins = NihilState.windowsOn(root.workspace?.id)
            const lead = wins.find(win => win.is_focused) ?? wins[0]
            if (lead) return AppSearch.lookupDesktopEntry(lead.app_id ?? "")?.name ?? String(lead.app_id ?? "")
            return String(root.at + 1).padStart(2, "0")
        }
        readonly property bool live: NiriService.inOverview

        screen: root.modelData
        // Niri keeps a backdrop surface out of the desktop and shows it only in the overview and between workspaces as
        // they slide. The namespace is the one every iNiR niri config already places in the backdrop, so no install
        // needs a new rule.
        visible: CompositorService.niriNative && NihilState.nativeStage
        color: NihilStyle.void_
        exclusionMode: ExclusionMode.Ignore
        WlrLayershell.layer: WlrLayer.Background
        WlrLayershell.namespace: "quickshell:iiBackdrop"
        anchors { top: true; bottom: true; left: true; right: true }
        mask: Region {}

        NFieldPaint {
            anchors.fill: parent
            form: Config.options?.nihil?.field?.form ?? 0
            seed: Config.options?.nihil?.field?.seed ?? 0.37
            glow: Config.options?.nihil?.field?.glow ?? 1
        }

        Image {
            anchors.fill: parent
            visible: (root.options?.posterWallpaper ?? 0.18) > 0
            opacity: root.options?.posterWallpaper ?? 0.18
            source: Wallpapers.effectiveWallpaperUrl
            sourceSize.width: 480
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            smooth: true
        }

        // The title fills the page's width, stretched if a short word needs it, and sits a little above the middle.
        Item {
            id: stage
            visible: root.subject !== "off"
            anchors.fill: parent
            readonly property real wide: root.width * 0.96
            readonly property real tall: root.height * 0.8
            NDisplay {
                id: title
                anchors.centerIn: parent
                anchors.verticalCenterOffset: -root.height * 0.03
                size: stage.tall
                text: root.title
                color: Qt.alpha(NihilStyle.ink, 0.92)
                bloom: 0.8
                transform: Scale {
                    origin.x: title.width / 2
                    origin.y: title.height / 2
                    xScale: stage.wide / Math.max(1, title.implicitWidth)
                    yScale: Math.min(1, stage.wide / Math.max(1, title.implicitWidth) * 1.6)
                }
            }
            NSpark { x: root.width * 0.06; y: root.height * 0.2; size: NihilStyle.s(72) }
            NSpark { x: root.width * 0.9; y: root.height * 0.68; size: NihilStyle.s(52) }
        }

        // The poster's foot: the day, the mark, the time.
        NRule {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: NihilStyle.s(26) }
            start: DateTime.date
            middle: "⋈"
            end: DateTime.time
        }
    }
}
