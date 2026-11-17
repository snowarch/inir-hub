// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.services
import "../state"

EditorSurface {
    id: root
    required property EditorSession session
    property bool output: false
    implicitHeight: column.implicitHeight + EditorSkin.pad * 2
    ColumnLayout {
        id: column
        anchors.fill: parent
        anchors.margins: EditorSkin.pad
        spacing: EditorSkin.small
        EditorText { visible: !root.output; text: Translation.tr("Original video"); font.weight: Font.Bold }
        Repeater {
            model: root.output ? [
                { label: Translation.tr("Duration"), value: root.session.timecode(root.session.renderDuration * 1000) },
                { label: root.session.renderFormat === "mp3" ? Translation.tr("Audio") : Translation.tr("Resolution"), value: root.session.renderFormat === "mp3" ? "MP3 192 kbps" : root.session.renderWidth + " × " + root.session.renderHeight },
                { label: Translation.tr("Original Size"), value: root.session.bytes(root.session.metadata.size) },
                { label: Translation.tr("Output Size"), value: root.session.bytes(root.session.renderOutputSize) }
            ] : [
                { label: Translation.tr("Duration"), value: root.session.timecode(root.session.durationMs) },
                { label: Translation.tr("Resolution"), value: (root.session.metadata.video?.width || 0) + " × " + (root.session.metadata.video?.height || 0) },
                { label: Translation.tr("FPS"), value: Number(root.session.metadata.video?.fps || 0).toFixed(2) },
                { label: Translation.tr("Bitrate"), value: (Number(root.session.metadata.format?.bitrate || 0) / 1000000).toFixed(2) + " Mbps" },
                { label: Translation.tr("Size"), value: root.session.bytes(root.session.metadata.size) }
            ]
            RowLayout {
                id: fact
                required property var modelData
                Layout.fillWidth: true
                EditorText { Layout.fillWidth: true; text: fact.modelData.label; color: EditorSkin.colors.muted; role: "meta" }
                EditorText { text: fact.modelData.value; role: "meta" }
            }
        }
    }
}
