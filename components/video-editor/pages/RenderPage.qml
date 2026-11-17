// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../state"
import "../controls"

ColumnLayout {
    id: root
    required property EditorSession session
    required property VideoBackend backend
    signal backRequested()
    spacing: EditorSkin.gap
    GridLayout {
        Layout.fillWidth: true
        columns: width >= Appearance.sizes.sidebarWidth * 2 ? 2 : 1
        rowSpacing: EditorSkin.pad
        columnSpacing: EditorSkin.pad
        EditorSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: width * 9 / 16 // literal: the original 16:9 render preview
            color: EditorSkin.colors.low
            clip: true
            Image {
                id: preview
                anchors.fill: parent
                anchors.margins: EditorSkin.gap
                source: root.session.renderFormat !== "mp3" ? root.session.thumbnails[0] || "" : ""
                fillMode: Image.PreserveAspectFit
                asynchronous: true
            }
            EditorStatus {
                visible: preview.status !== Image.Ready
                anchors.centerIn: parent
                symbol: root.session.renderFormat === "mp3" ? "music_note" : "movie"
                title: root.session.renderFormat === "mp3" ? Translation.tr("Audio Track") : Translation.tr("Preview unavailable")
            }
        }
        EditorSurface {
            Layout.fillWidth: true
            implicitHeight: status.implicitHeight + EditorSkin.pad * 2
            EditorStatus {
                id: status
                anchors.fill: parent
                anchors.margins: EditorSkin.pad
                error: root.session.renderState === "error"
                symbol: root.session.renderState === "done" ? "check_circle" : error ? "error" : "hourglass_top"
                title: root.session.renderState === "cancelling" ? Translation.tr("Cancelling export…") : root.session.renderState === "done" ? Translation.tr("Export Complete!") : error ? Translation.tr("Export Failed") : root.session.renderFormat === "mp3" ? Translation.tr("Extracting Audio (MP3)…") : root.session.renderFormat === "gif" ? Translation.tr("Generating GIF Animation…") : Translation.tr("Rendering Video (MP4)…")
                detail: error ? root.session.renderError || Translation.tr("Video processing failed.") : root.session.renderState === "done" ? Translation.tr("Your media is ready to view and share.") : ""
                ColumnLayout {
                    visible: root.session.renderState === "rendering"
                    Layout.fillWidth: true
                    StyledProgressBar { Layout.fillWidth: true; value: root.session.renderProgress; valueBarHeight: EditorSkin.small; highlightColor: EditorSkin.colors.accent; trackColor: EditorSkin.colors.plate }
                    EditorText { text: Math.round(root.session.renderProgress * 100) + "%"; color: EditorSkin.colors.accent; role: "title" }
                    EditorText { text: root.session.renderElapsed > 0 ? Translation.tr("Elapsed: %1").arg(root.session.timecode(root.session.renderElapsed * 1000)) : Translation.tr("Starting…"); color: EditorSkin.colors.muted; role: "meta" }
                    EditorAction { label: Translation.tr("Cancel"); symbol: "close"; onClicked: root.session.cancelRequested() }
                }
            }
        }
    }
    EditorFacts { output: true; Layout.fillWidth: true; session: root.session }
    Flow {
        Layout.fillWidth: true
        spacing: EditorSkin.small
        EditorAction {
            visible: root.session.renderState === "done"
            label: root.session.renderFormat === "mp3" ? Translation.tr("Open Audio") : root.session.renderFormat === "gif" ? Translation.tr("Open GIF") : Translation.tr("Open Video")
            symbol: "play_arrow"
            primary: true
            enabled: !root.backend.actionBusy
            onClicked: root.backend.openOutput(false)
        }
        EditorAction { visible: root.session.renderState === "done"; label: Translation.tr("Open Folder"); symbol: "folder_open"; enabled: !root.backend.actionBusy; onClicked: root.backend.openOutput(true) }
        EditorAction { visible: root.session.renderState === "done"; label: root.backend.copied ? Translation.tr("Copied!") : Translation.tr("Copy Path"); symbol: "content_copy"; enabled: !root.backend.actionBusy; onClicked: root.backend.copyPath() }
        EditorAction { label: Translation.tr("Back to Editor"); symbol: "arrow_back"; onClicked: root.backRequested() }
    }
}
