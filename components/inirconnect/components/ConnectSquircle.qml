pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.components
import "../state"

Item {
    id: root

    property color tint: ConnectStyle.gray
    property string glyph: "settings"
    property real glyphShare: 0.64
    readonly property bool _inlineSmall: Math.min(root.width, root.height) <= 20

    Loader {
        anchors.fill: parent
        active: ConnectStyle.isIris
        sourceComponent: Component {
            IrisSquircle {
                tint: root.tint
                glyph: root.glyph
                glyphShare: root.glyphShare
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !ConnectStyle.isIris
        radius: root._inlineSmall ? 0 : Math.round(Math.min(width, height) * 0.28)
        color: root._inlineSmall ? "transparent" : ConnectStyle.tintFill(root.tint)

        MaterialSymbol {
            anchors.centerIn: parent
            text: root.glyph
            fill: 1
            iconSize: Math.round(Math.min(root.width, root.height) * (root._inlineSmall ? 0.92 : root.glyphShare))
            color: root.tint
        }
    }
}
