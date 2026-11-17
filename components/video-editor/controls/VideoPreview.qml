// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtMultimedia
import qs.services
import qs.modules.common.widgets
import "../state"

EditorSurface {
    id: root
    required property EditorSession session
    required property PlaybackController playback
    signal browseRequested()
    color: EditorSkin.colors.low
    clip: true
    Component.onCompleted: root.playback.videoOutput = output
    Component.onDestruction: root.playback.videoOutput = null
    VideoOutput {
        id: output
        anchors.centerIn: parent
        width: root.session.rotation % 180 === 0 ? root.width : root.height
        height: root.session.rotation % 180 === 0 ? root.height : root.width
        visible: root.session.ready
        fillMode: VideoOutput.PreserveAspectFit
        transform: [
            Rotation { angle: root.session.rotation; origin.x: output.width / 2; origin.y: output.height / 2 },
            Scale { xScale: root.session.flipHorizontal ? -1 : 1; yScale: root.session.flipVertical ? -1 : 1; origin.x: output.width / 2; origin.y: output.height / 2 }
        ]
        Loader {
            active: root.session.cropEnabled && root.session.ready
            x: output.contentRect.x; y: output.contentRect.y
            width: output.contentRect.width; height: output.contentRect.height
            sourceComponent: CropOverlay { session: root.session }
        }
    }
    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width - EditorSkin.pad * 2
        visible: !root.session.ready
        spacing: EditorSkin.gap
        MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: root.session.status === "error" ? "error" : "upload_file"; iconSize: EditorSkin.title * 2; color: root.session.status === "error" ? EditorSkin.colors.error : EditorSkin.colors.accent }
        EditorText { Layout.fillWidth: true; text: root.session.status === "error" ? root.session.errorMessage : root.session.status === "loading" ? Translation.tr("Loading video…") : Translation.tr("Drag and drop a video here"); font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: root.session.status === "error" ? EditorSkin.colors.error : EditorSkin.colors.text }
        EditorText { visible: root.session.status === "error" && root.session.errorDetail !== ""; Layout.fillWidth: true; text: root.session.errorDetail; wrapMode: Text.WrapAnywhere; maximumLineCount: 6; elide: Text.ElideRight; role: "meta"; color: EditorSkin.colors.error }
        StyledIndeterminateProgressBar { visible: root.session.status === "loading"; Layout.fillWidth: true }
        EditorAction { Layout.alignment: Qt.AlignHCenter; label: Translation.tr("Browse Files"); symbol: "folder_open"; primary: true; onClicked: root.browseRequested() }
    }
    EditorAction {
        visible: root.session.ready
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        anchors.margins: EditorSkin.gap
        symbol: root.playback.playing ? "pause" : "play_arrow"
        hint: Translation.tr("Play or pause (Space)")
        onClicked: root.playback.toggle()
    }
    EditorText {
        visible: root.session.ready && root.playback.loading
        anchors.centerIn: parent
        text: Translation.tr("Loading preview…")
    }
    DropArea {
        anchors.fill: parent
        onDropped: drop => { if (drop.hasUrls && drop.urls.length) root.session.load(drop.urls[0].toString()); }
        Rectangle {
            anchors.fill: parent
            visible: parent.containsDrag
            radius: root.radius
            color: EditorSkin.colors.card
            EditorText { anchors.centerIn: parent; text: Translation.tr("Drop to open video"); font.pixelSize: EditorSkin.body }
        }
    }
}
