import QtQuick
import qs.modules.iris.prism.core

// The reference's pills: `solid` is the white Play pill, `dark` the smoked View Playlist one over art, `quiet` a fill
// on Prism's own page. A glyph leads when given.
Item {
    id: root
    property string text: ""
    property string glyph: ""
    property string tone: "solid" // solid | art (white on the art in every scheme) | dark | quiet
    property bool enabled_: true
    signal clicked()

    readonly property bool hovered: area.containsMouse
    readonly property color background: root.tone === "art" ? PrismTheme.paper : root.tone === "solid" ? PrismTheme.solid
        : root.tone === "dark" ? Qt.rgba(1, 1, 1, area.pressed ? 0.2 : root.hovered ? 0.16 : 0.1) // iris-literal: Prism's own fills and scrims, scheme-aware above
        : area.pressed ? PrismTheme.fillPress : root.hovered ? PrismTheme.fillHover : PrismTheme.fill
    readonly property color ink: root.tone === "art" ? PrismTheme.night : root.tone === "solid" ? PrismTheme.inkSolid : root.tone === "dark" ? PrismTheme.paper : PrismTheme.ink

    implicitHeight: PrismTheme.dp(34)
    implicitWidth: row.implicitWidth + PrismTheme.dp(root.glyph.length > 0 ? 30 : 36)
    opacity: root.enabled_ ? 1 : 0.38
    scale: area.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: PrismTheme.ms(140); easing.type: Easing.OutCubic } }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: root.background
        Behavior on color { ColorAnimation { duration: PrismTheme.ms(120) } }
    }
    Row {
        id: row
        anchors.centerIn: parent
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
