// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common.widgets
import "../state"

ColumnLayout {
    id: root
    required property EditorSession session
    required property PlaybackController playback
    spacing: EditorSkin.small
    RowLayout {
        Layout.fillWidth: true
        EditorText { text: Translation.tr("Trim Video"); font.weight: Font.Medium }
        Item { Layout.fillWidth: true }
        EditorText {
            text: root.session.thumbnailsLoading ? Translation.tr("Loading thumbnails…") : root.session.thumbnails.length ? "" : Translation.tr("Thumbnails unavailable")
            role: "meta"
            color: EditorSkin.colors.muted
        }
    }
    Item {
        id: track
        Layout.fillWidth: true
        Layout.preferredHeight: EditorSkin.title + EditorSkin.pad
        readonly property real duration: Math.max(1, root.session.durationMs)
        Rectangle { anchors.fill: parent; radius: EditorSkin.smallRadius; color: EditorSkin.colors.plate }
        Row {
            anchors.fill: parent
            clip: true
            Repeater {
                model: root.session.thumbnails
                Image { required property var modelData; width: track.width / Math.max(1, root.session.thumbnails.length); height: track.height; source: modelData || ""; fillMode: Image.PreserveAspectCrop; asynchronous: true }
            }
        }
        Rectangle { width: root.session.startMs / track.duration * track.width; height: parent.height; color: EditorSkin.colors.scrim }
        Rectangle { x: root.session.effectiveEndMs / track.duration * track.width; width: parent.width - x; height: parent.height; color: EditorSkin.colors.scrim }
        EditorRange {
            anchors.fill: parent
            from: 0; to: track.duration; value: root.playback.position
            formatValue: next => root.session.timecode(next)
            onMoved: next => root.playback.seek(next)
            Accessible.name: Translation.tr("Trim Video")
        }
        HoverHandler { id: hover }
        component TrimHandle: Rectangle {
            id: handle
            required property bool inPoint
            x: (inPoint ? root.session.startMs : root.session.effectiveEndMs) / track.duration * track.width - width / 2
            width: EditorSkin.pad
            height: track.height
            radius: EditorSkin.smallRadius
            color: EditorSkin.colors.accent
            MaterialSymbol { anchors.centerIn: parent; text: handle.inPoint ? "chevron_right" : "chevron_left"; iconSize: EditorSkin.body; color: EditorSkin.colors.onAccent }
            DragHandler {
                target: null
                property real initial: 0
                onActiveChanged: { if (active) { initial = handle.inPoint ? root.session.startMs : root.session.effectiveEndMs; root.playback.pause(); } else root.playback.play(); }
                onActiveTranslationChanged: if (active) {
                    const position = initial + activeTranslation.x / track.width * root.session.durationMs;
                    if (handle.inPoint) root.session.setInPoint(position); else root.session.setOutPoint(position);
                    root.playback.seek(handle.inPoint ? root.session.startMs : root.session.effectiveEndMs);
                }
            }
        }
        TrimHandle { inPoint: true }
        TrimHandle { inPoint: false }
        StyledToolTip {
            visible: hover.hovered && root.session.ready
            text: root.session.timecode(hover.point.position.x / track.width * root.session.durationMs)
            font.family: EditorSkin.mainFont
        }
    }

    RowLayout {
        Layout.fillWidth: true
        EditorText { text: root.session.timecode(root.session.startMs); color: EditorSkin.colors.accent; role: "meta" }
        Item { Layout.fillWidth: true }
        EditorText { text: root.session.timecode(root.session.effectiveEndMs); color: EditorSkin.colors.accent; role: "meta" }
    }
}
