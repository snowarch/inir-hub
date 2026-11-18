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
        // The workspace's name, else what lives there, else the day: a word wide enough to show past the
        // workspace standing in front of it.
        readonly property string title: {
            if (root.subject === "clock") return DateTime.time
            const name = String(root.workspace?.name ?? "")
            if (name.length > 0) return name
            const wins = NihilState.windowsOn(root.workspace?.id)
            const lead = wins.find(win => win.is_focused) ?? wins[0]
            if (lead) return AppSearch.lookupDesktopEntry(lead.app_id ?? "")?.name ?? String(lead.app_id ?? "")
            return Qt.locale().dayName(new Date().getDay(), Locale.LongFormat)
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

        // The compositor shrinks the workspaces to `zoom` of the screen and centres them, which leaves a gutter on each
        // side. The title runs up the left gutter like a poster's spine, as tall as the gutter is wide, so the live
        // workspace never hides it.
        readonly property real zoom: Number(CompositorConfig.value({ comp: "layout", key: "overview.zoom",
            read: "overview_zoom", fallback: 0.5 })) || 0.5
        readonly property real gutter: root.width * (1 - NihilStyle.clamp(root.zoom, 0.2, 0.9)) / 2

        Item {
            id: stage
            visible: root.subject !== "off" && root.gutter > NihilStyle.s(120)
            x: (root.gutter - width) / 2
            width: root.gutter * 0.78
            height: root.height
            readonly property real reach: root.height * 0.82

            NDisplay {
                id: title
                anchors.centerIn: parent
                width: implicitWidth
                height: implicitHeight
                size: stage.width * 1.12
                text: root.title
                color: Qt.alpha(NihilStyle.ink, 0.94)
                bloom: 0.8
                rotation: -90
                scale: Math.min(1, stage.reach / Math.max(1, title.implicitWidth))
            }
            NSpark { x: stage.width + NihilStyle.s(8); y: root.height * 0.14; size: NihilStyle.s(48) }
        }
        NSpark { visible: stage.visible; x: root.width - root.gutter * 0.5; y: root.height * 0.82; size: NihilStyle.s(36) }

        // The page's head over the right gutter: which workspace of how many, set as a poster's issue number.
        NDisplay {
            visible: stage.visible
            anchors.right: parent.right
            anchors.rightMargin: NihilStyle.s(28)
            y: root.height * 0.08
            text: String(root.at + 1).padStart(2, "0")
            size: NihilStyle.s(88)
            color: Qt.alpha(NihilStyle.ink, 0.22)
            bloom: 0
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
