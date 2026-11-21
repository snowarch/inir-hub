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
    // On the page: no face at rest, a quiet plate under the pointer (the window's own keys).
    property bool ghost: false
    // A ghost in the accent: its glyph and its plate under the pointer (the way back to iNiR's).
    property bool accented: false
    property real glyphSize: PrismTheme.dp(18)
    signal clicked()

    readonly property bool hovered: area.containsMouse
    implicitWidth: PrismTheme.dp(32)
    implicitHeight: implicitWidth
    opacity: root.enabled_ ? 1 : 0.32
    readonly property bool glass: root.overArt && !root.solid && !root.lit

    Rectangle {
        visible: root.ghost
        anchors.fill: parent
        radius: width / 2
        color: root.accented && (area.pressed || root.hovered) ? PrismTheme.accentPlate
            : area.pressed ? PrismTheme.fillPress : root.hovered ? PrismTheme.fillHover : "transparent"
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    PrismKey {
        visible: !root.glass && !root.ghost
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
    }
    PrismGlyph {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: root.glass ? 0 : (area.pressed ? PrismTheme.keyLip / 2 : -PrismTheme.keyLip / 2)
        text: root.glyph
        filled: true
        iconSize: root.glyphSize
        color: root.solid ? (root.overArt ? "#000000" : PrismTheme.inkSolid) // iris-literal: ink on the white disc over art
            : root.lit ? PrismTheme.inkAccent : root.overArt ? PrismTheme.paper : root.accented ? PrismTheme.accentInk
            : root.ghost && !root.hovered ? PrismTheme.ink2 : PrismTheme.ink
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
