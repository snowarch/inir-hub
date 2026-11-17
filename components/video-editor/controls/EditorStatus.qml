// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.common.widgets

ColumnLayout {
    id: root
    property string symbol: ""
    required property string title
    property string detail: ""
    property bool error: false
    default property alias actions: extras.data
    spacing: EditorSkin.gap
    MaterialSymbol { Layout.alignment: Qt.AlignHCenter; text: root.symbol; iconSize: EditorSkin.title * 2; color: root.error ? EditorSkin.colors.error : EditorSkin.colors.accent }
    EditorText { Layout.fillWidth: true; text: root.title; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; wrapMode: Text.Wrap; color: root.error ? EditorSkin.colors.error : EditorSkin.colors.text }
    EditorText { visible: root.detail !== ""; Layout.fillWidth: true; text: root.detail; wrapMode: Text.WrapAnywhere; maximumLineCount: 6; elide: Text.ElideRight; role: "meta"; color: root.error ? EditorSkin.colors.error : EditorSkin.colors.muted }
    ColumnLayout { id: extras; Layout.fillWidth: true; spacing: EditorSkin.small }
}
