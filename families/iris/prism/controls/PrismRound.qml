import QtQuick
import qs.modules.iris.prism.core

// A circle with one glyph: back and forward, the bell, the transport. `solid` is the white one that leads.
Item {
    id: root
    property string glyph: "circle"
    property bool solid: false
    property bool lit: false
    property bool enabled_: true
    property bool overArt: false
    // Over art, a smoked disc at rest (the dark pill's twin) instead of a bare glyph.
    property bool smoked: false
    property real glyphSize: PrismTheme.dp(18)
    signal clicked()

    readonly property bool hovered: area.containsMouse
    implicitWidth: PrismTheme.dp(32)
    implicitHeight: implicitWidth
    opacity: root.enabled_ ? 1 : 0.32
    scale: area.pressed ? 0.92 : 1
    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: root.solid ? (root.overArt ? PrismTheme.paper : PrismTheme.solid)
            : root.lit ? PrismTheme.accent
            : root.overArt ? Qt.rgba(1, 1, 1, area.pressed ? 0.22 : root.hovered ? 0.16 : root.smoked ? 0.1 : 0) // iris-literal: Prism's own fills and scrims, scheme-aware above
            : area.pressed ? PrismTheme.fillPress : root.hovered ? PrismTheme.fillHover : PrismTheme.fill
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120) } }
    }
    PrismGlyph {
        anchors.centerIn: parent
        text: root.glyph
        filled: true
        iconSize: root.glyphSize
        color: root.solid ? (root.overArt ? "#000000" : PrismTheme.inkSolid) // iris-literal: ink on the white disc over art
            : root.lit ? PrismTheme.inkAccent : root.overArt ? PrismTheme.paper : PrismTheme.ink
    }
    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        enabled: root.enabled_
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
