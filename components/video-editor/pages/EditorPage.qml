// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import "../state"
import "../controls"

ColumnLayout {
    id: root
    required property EditorSession session
    required property PlaybackController playback
    required property VideoBackend backend
    signal closeRequested()
    spacing: EditorSkin.gap
    FilePickerDialog {
        id: picker
        title: Translation.tr("Open Video")
        nameFilters: [Translation.tr("Videos (*.mp4 *.mkv *.webm *.avi *.mov)")]
        currentFolder: Directories.videos
        onAccepted: root.session.load(String(selectedFile))
    }
    RowLayout {
        Layout.fillWidth: true
        spacing: EditorSkin.gap
        EditorAction { visible: root.session.renderOpen; symbol: "arrow_back"; hint: Translation.tr("Back to Editor"); onClicked: root.session.cancelRequested() }
        MaterialSymbol { visible: !root.session.renderOpen; text: "movie_edit"; iconSize: EditorSkin.title; color: EditorSkin.colors.accent }
        EditorText { Layout.fillWidth: true; text: !root.session.renderOpen ? Translation.tr("Video Editor") : root.session.renderState === "done" ? Translation.tr("Export Complete") : root.session.renderState === "error" ? Translation.tr("Export Failed") : Translation.tr("Export & Render"); role: "title"; font.weight: Font.Bold; elide: Text.ElideRight }
        EditorAction { visible: !root.session.renderOpen; symbol: "photo_camera"; hint: Translation.tr("Snapshot frame (P)"); enabled: root.session.ready; onClicked: root.session.snapshotRequested() }
        EditorAction { visible: !root.session.renderOpen; symbol: "info"; hint: Translation.tr("Original video"); selected: root.session.infoOpen; enabled: root.session.ready; onClicked: root.session.infoOpen = !root.session.infoOpen }
        EditorAction { symbol: "close"; hint: Translation.tr("Close video editor"); onClicked: root.closeRequested() }
    }
    EditorText { visible: root.session.renderOpen; text: root.session.renderOutputPath.split("/").pop() || root.session.fileName; color: EditorSkin.colors.muted; role: "meta" }
    VideoPreview {
        visible: !root.session.renderOpen
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.minimumHeight: Appearance.sizes.mediaControlsHeight
        session: root.session
        playback: root.playback
        onBrowseRequested: picker.open()
    }
    EditorText {
        visible: root.session.auxiliaryError !== ""
        Layout.fillWidth: true
        text: root.session.auxiliaryError
        wrapMode: Text.Wrap
        color: EditorSkin.colors.error
        role: "meta"
    }
    EditorText {
        visible: !root.session.renderOpen && root.session.snapshotPath !== ""
        Layout.fillWidth: true
        text: Translation.tr("Snapshot saved: %1").arg(root.session.snapshotPath.split("/").pop())
        elide: Text.ElideMiddle
        color: EditorSkin.colors.accent
        role: "meta"
    }
    TrimTimeline { visible: root.session.ready && !root.session.renderOpen; Layout.fillWidth: true; session: root.session; playback: root.playback }
    ScrollView {
        id: scroll
        visible: root.session.ready
        Layout.fillWidth: true
        Layout.fillHeight: root.session.renderOpen
        Layout.preferredHeight: root.session.renderOpen ? -1 : Math.min(tools.implicitHeight, root.height / 2)
        contentWidth: availableWidth
        contentHeight: tools.implicitHeight
        ColumnLayout {
            id: tools
            width: scroll.availableWidth
            spacing: EditorSkin.gap
            EditorFacts { visible: !root.session.renderOpen && root.session.infoOpen; Layout.fillWidth: true; session: root.session }
            Loader {
                Layout.fillWidth: true
                sourceComponent: root.session.renderOpen ? renderContent : editContent
                Component { id: editContent; EditorTools { session: root.session; playback: root.playback } }
                Component { id: renderContent; RenderPage { session: root.session; backend: root.backend; onBackRequested: root.session.cancelRequested() } }
            }
        }
    }
}
