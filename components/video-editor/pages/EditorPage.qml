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
    property bool windowed: true
    readonly property bool dialogOpen: picker.visible
    signal switchHostRequested()
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
        Layout.preferredHeight: Math.round(36 * EditorSkin.d)
        spacing: EditorSkin.small
        EditorAction { visible: root.session.renderOpen; chrome: true; symbol: "arrow_back"; hint: Translation.tr("Back to Editor"); onClicked: root.session.cancelRequested() }
        MaterialSymbol {
            visible: !root.session.renderOpen
            text: "movie_edit"
            iconSize: EditorSkin.markSize
            color: EditorSkin.colors.accent
        }
        EditorText {
            Layout.fillWidth: true
            text: !root.session.renderOpen ? Translation.tr("Video Editor") : root.session.renderState === "done" ? Translation.tr("Export Complete") : root.session.renderState === "error" ? Translation.tr("Export Failed") : Translation.tr("Export & Render")
            role: "title"
            elide: Text.ElideRight
        }
        EditorStyleSwitch {
            glyphOnly: EditorSkin.classic || root.width < Math.round(720 * EditorSkin.d)
        }
        EditorAction { visible: !root.session.renderOpen; chrome: true; symbol: "photo_camera"; hint: Translation.tr("Snapshot frame (P)"); enabled: root.session.ready; onClicked: root.session.snapshotRequested() }
        EditorAction { visible: !root.session.renderOpen; chrome: true; symbol: "info"; hint: Translation.tr("Original video"); selected: root.session.infoOpen; enabled: root.session.ready; onClicked: root.session.infoOpen = !root.session.infoOpen }
        EditorAction {
            chrome: true
            symbol: root.windowed ? "layers" : "open_in_new"
            hint: root.windowed ? Translation.tr("Open over the desktop") : Translation.tr("Open in a window")
            onClicked: root.switchHostRequested()
        }
        EditorAction { chrome: true; symbol: "close"; hint: Translation.tr("Close video editor"); onClicked: root.closeRequested() }
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
        readonly property int sideBleed: root.session.renderOpen ? 0 : Math.round(EditorSkin.small)
        Layout.fillWidth: true
        Layout.leftMargin: -scroll.sideBleed
        Layout.rightMargin: -scroll.sideBleed
        Layout.fillHeight: root.session.renderOpen
        Layout.preferredHeight: root.session.renderOpen ? -1 : Math.min(tools.implicitHeight, root.height / 2)
        contentWidth: availableWidth
        contentHeight: tools.implicitHeight
        ColumnLayout {
            id: tools
            width: scroll.availableWidth
            spacing: EditorSkin.gap
            EditorFacts {
                visible: !root.session.renderOpen && root.session.infoOpen
                Layout.fillWidth: true
                Layout.leftMargin: scroll.sideBleed
                Layout.rightMargin: scroll.sideBleed
                session: root.session
            }
            Loader {
                Layout.fillWidth: true
                sourceComponent: root.session.renderOpen ? renderContent : editContent
                Component { id: editContent; EditorTools { session: root.session; playback: root.playback } }
                Component { id: renderContent; RenderPage { session: root.session; backend: root.backend; onBackRequested: root.session.cancelRequested() } }
            }
        }
    }
}
