import QtQuick
import qs.modules.iris.prism.core

// A round key with one glyph: back and forward, the bell, the transport. `solid` is the white one that leads; over art
// it is smoked glass, a disc at rest when `smoked`.
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
    readonly property bool glass: root.overArt && !root.solid && !root.lit

    PrismKey {
        visible: !root.glass
        anchors.fill: parent
        face: root.solid ? (root.overArt ? PrismTheme.paper : PrismTheme.solid) : root.lit ? PrismTheme.accent : PrismTheme.keyQuiet
        hovered: root.hovered && root.enabled_
        down: area.pressed
    }
    Rectangle {
        visible: root.glass && (root.smoked || root.hovered)
        anchors.fill: parent
        radius: width / 2
        color: area.pressed ? PrismTheme.spotPress : root.hovered ? PrismTheme.spotHover : PrismTheme.spot
        border.width: 1
        border.color: PrismTheme.spotEdge
    }
    PrismGlyph {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.glass ? 0 : (area.pressed ? PrismTheme.keyLip / 2 : -PrismTheme.keyLip / 2)
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
