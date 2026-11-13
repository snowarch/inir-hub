import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// A row's cover: a small tinted squircle with its glyph, as the reference's album thumbnails.
Rectangle {
    id: root
    property string glyph: "circle"
    property string tint: "grey"
    property real size: PrismTheme.dp(36)
    width: root.size
    height: root.size
    radius: Math.round(root.size * 0.24)
    gradient: Gradient {
        GradientStop { position: 0; color: Qt.lighter(PrismTheme.tint(root.tint), 1.18) }
        GradientStop { position: 1; color: Qt.darker(PrismTheme.tint(root.tint), 1.25) }
    }
    PrismGlyph {
        anchors.centerIn: parent
        text: root.glyph
        filled: true
        iconSize: Math.round(root.size * 0.5)
        color: PrismTheme.paper
    }
}
