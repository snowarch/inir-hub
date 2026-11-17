// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import qs
import qs.services
import qs.modules.common.widgets
import "controls"

PanelWindow {
    id: root
    required property string videoPath
    property string errorMessage: ""
    property bool busy: false
    signal dismissed()
    signal editRequested()
    // Capture the output once: a live layer window keeps its screen and anchors.
    Component.onCompleted: root.screen = GlobalStates.focusedScreen
    WlrLayershell.namespace: "quickshell:video-editor"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    visible: !GlobalStates.screenLocked
    exclusionMode: ExclusionMode.Ignore
    color: "transparent" // literal: no paint outside the rounded prompt
    anchors { top: true; right: true }
    margins { top: EditorSkin.pad; right: EditorSkin.pad }
    implicitWidth: Math.min(400, Math.max(0, (root.screen?.width ?? (400 + EditorSkin.pad * 2)) - EditorSkin.pad * 2)) // literal: requested compact prompt width cap
    implicitHeight: content.implicitHeight + EditorSkin.pad * 2
    mask: Region { item: card }
    Timer {
        interval: 8000 // literal: the original prompt's dismissal interval
        running: !GlobalStates.screenLocked && !hover.hovered && !root.busy && root.errorMessage === ""
        onTriggered: root.dismissed()
    }
    EditorSurface {
        id: card
        anchors.fill: parent
        color: EditorSkin.colors.page
        focus: true
        Keys.onEscapePressed: root.dismissed()
        HoverHandler { id: hover }
        ColumnLayout {
            id: content
            anchors.fill: parent
            anchors.margins: EditorSkin.pad
            spacing: EditorSkin.gap
            RowLayout {
                Layout.fillWidth: true
                MaterialSymbol { text: "movie_edit"; iconSize: EditorSkin.title; color: EditorSkin.colors.accent }
                EditorText {
                    Layout.fillWidth: true
                    text: Translation.tr("Recording Finished")
                    font.weight: Font.Bold
                }
                EditorAction { symbol: "close"; hint: Translation.tr("Dismiss"); onClicked: root.dismissed() }
            }
            EditorText { text: Translation.tr("Do you want to edit it?"); color: EditorSkin.colors.muted }
            EditorText {
                Layout.fillWidth: true
                text: root.videoPath.split("/").pop()
                elide: Text.ElideMiddle
                role: "meta"
                color: EditorSkin.colors.muted
            }
            EditorText { visible: root.errorMessage !== ""; Layout.fillWidth: true; text: root.errorMessage; wrapMode: Text.Wrap; color: EditorSkin.colors.error }
            EditorAction {
                label: root.busy ? Translation.tr("Opening…") : Translation.tr("Edit Video")
                symbol: "edit"
                primary: true
                enabled: !root.busy
                onClicked: root.editRequested()
            }
        }
    }
}
