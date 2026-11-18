pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import qs
import qs.modules.common
import qs.services
import qs.modules.nihil.style
import qs.modules.nihil.state

// What the compositor's overview stands on. Niri draws this surface in its backdrop, behind the workspaces it shrinks:
// the wallpaper, blurred and dimmed under a soft vignette, or the family's field. Nothing here takes input.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: root

        required property var modelData
        readonly property string output: root.modelData.name
        readonly property var options: Config.options?.nihil?.overview
        // "wallpaper" (blurred), "field" (the procedural field) or "off" (graphite).
        readonly property string subject: ({ workspace: "wallpaper", clock: "wallpaper" })[root.options?.poster] ?? root.options?.poster ?? "wallpaper"
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
            visible: root.subject === "field"
            form: Config.options?.nihil?.field?.form ?? 0
            seed: Config.options?.nihil?.field?.seed ?? 0.37
            glow: Config.options?.nihil?.field?.glow ?? 1
        }

        Image {
            id: picture
            anchors.fill: parent
            visible: false
            source: root.subject === "wallpaper" ? Wallpapers.effectiveWallpaperUrl : ""
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
        }
        MultiEffect {
            anchors.fill: parent
            visible: root.subject === "wallpaper" && picture.status === Image.Ready
            source: picture
            blurEnabled: true
            blur: 1
            blurMax: 48
            saturation: -0.15
            opacity: NihilStyle.clamp(Number(root.options?.posterWallpaper ?? 0.6), 0, 1)
        }
        // A vignette that settles the edges, so the workspaces read as the light in the middle.
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0; color: Qt.alpha(NihilStyle.void_, 0.55) }
                GradientStop { position: 0.35; color: Qt.alpha(NihilStyle.void_, 0.15) }
                GradientStop { position: 0.7; color: Qt.alpha(NihilStyle.void_, 0.2) }
                GradientStop { position: 1; color: Qt.alpha(NihilStyle.void_, 0.65) }
            }
        }
    }
}
