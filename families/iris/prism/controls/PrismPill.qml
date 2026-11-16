import QtQuick
import qs.modules.iris.prism.core

// Pills (`.claude/ref/language`): `solid` is the white key that acts, `art` the same white over art in every scheme,
// `quiet` a key on Prism's own page; each stands on its lip and sinks when pressed. `dark` is the smoked glass that
// says a value over art. A glyph leads when given.
Item {
    id: root
    property string text: ""
    property string glyph: ""
    property string tone: "solid" // solid | art (white on the art in every scheme) | dark | quiet
    property bool enabled_: true
    signal clicked()

    readonly property bool hovered: area.containsMouse
    readonly property color face: root.tone === "art" ? PrismTheme.paper : root.tone === "solid" ? PrismTheme.solid : PrismTheme.keyQuiet
    readonly property color ink: root.tone === "art" ? PrismTheme.night : root.tone === "solid" ? PrismTheme.inkSolid : root.tone === "dark" ? PrismTheme.paper : PrismTheme.ink

    implicitHeight: PrismTheme.dp(34)
    implicitWidth: row.implicitWidth + PrismTheme.dp(root.glyph.length > 0 ? 30 : 36)
    opacity: root.enabled_ ? 1 : 0.38

    PrismKey {
        id: key
        visible: root.tone !== "dark"
        anchors.fill: parent
        face: root.face
        hovered: root.hovered
        down: area.pressed
    }
    Rectangle {
        visible: root.tone === "dark"
        anchors.fill: parent
        radius: height / 2
        color: area.pressed ? PrismTheme.spotPress : root.hovered ? PrismTheme.spotHover : PrismTheme.spot
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120); easing.type: Easing.OutCubic } }
    }
    Row {
        id: row
        anchors.centerIn: parent
        // On a key the words ride its cap, a lip above the foot, and sink with it.
        anchors.verticalCenterOffset: root.tone === "dark" ? 0 : (area.pressed ? PrismTheme.keyLip / 2 : -PrismTheme.keyLip / 2)
        spacing: PrismTheme.dp(6)
        PrismGlyph {
            visible: root.glyph.length > 0
            anchors.verticalCenter: parent.verticalCenter
            text: root.glyph
            filled: true
            iconSize: PrismTheme.dp(16)
            color: root.ink
        }
        PrismText {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.ink
            font.pixelSize: PrismTheme.small
            font.weight: Font.DemiBold
        }
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
