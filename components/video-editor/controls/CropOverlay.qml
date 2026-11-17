// SPDX-License-Identifier: GPL-3.0-only
pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.common.widgets
import "../state"

Item {
    id: root
    required property EditorSession session
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; height: box.y; color: EditorSkin.colors.scrim }
    Rectangle { anchors.left: parent.left; anchors.right: parent.right; y: box.y + box.height; height: Math.max(0, root.height - y); color: EditorSkin.colors.scrim }
    Rectangle { y: box.y; width: box.x; height: box.height; color: EditorSkin.colors.scrim }
    Rectangle { x: box.x + box.width; y: box.y; width: Math.max(0, root.width - x); height: box.height; color: EditorSkin.colors.scrim }
    Rectangle {
        id: box
        x: root.session.cropX * root.width
        y: root.session.cropY * root.height
        width: root.session.cropW * root.width
        height: root.session.cropH * root.height
        color: "transparent" // literal: only the crop outline paints
        border.color: EditorSkin.colors.accent
        border.width: EditorSkin.small / 4
        DragHandler {
            target: null
            property real initialX: 0
            property real initialY: 0
            onActiveChanged: if (active) { initialX = root.session.cropX; initialY = root.session.cropY; }
            onActiveTranslationChanged: if (active) root.session.moveCrop(initialX + activeTranslation.x / root.width, initialY + activeTranslation.y / root.height)
        }
        Rectangle {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            width: EditorSkin.body + EditorSkin.small
            height: width
            radius: EditorSkin.smallRadius
            color: EditorSkin.colors.accent
            MaterialSymbol { anchors.centerIn: parent; text: "expand_content"; iconSize: EditorSkin.body; color: EditorSkin.colors.onAccent }
            DragHandler {
                target: null
                property real initialW: 0
                property real initialH: 0
                onActiveChanged: if (active) { initialW = root.session.cropW; initialH = root.session.cropH; }
                onActiveTranslationChanged: if (active) root.session.resizeCrop(initialW + activeTranslation.x / root.width, initialH + activeTranslation.y / root.height)
            }
        }
    }
}
