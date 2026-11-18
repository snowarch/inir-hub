import QtQuick

// A pill key with a glyph and a word (Bluetooth, Settings, Energy Saver), centred, lit in the signal when on. `opens`
// adds a chevron at its end that leads to the key's list (`opened`); the rest of the key still toggles.
NButton {
    id: root

    property string label: ""
    property string glyph: ""
    property bool stacked: false
    property bool opens: false
    signal opened()

    tone: NihilStyle.pieceRaised

    Row {
        anchors.centerIn: parent
        anchors.horizontalCenterOffset: root.opens ? -NihilStyle.s(10) : 0
        spacing: NihilStyle.s(8)
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph.length > 0
            text: root.glyph
            size: NihilStyle.s(18)
            color: root.ink
        }
        NText {
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, root.width - NihilStyle.s(root.glyph.length > 0 ? 48 : 20) - (root.opens ? NihilStyle.s(22) : 0))
            text: root.label
            font.pixelSize: NihilStyle.s(13)
            font.weight: Font.Medium
            color: root.ink
            horizontalAlignment: Text.AlignHCenter
            wrapMode: root.stacked ? Text.WordWrap : Text.NoWrap
            maximumLineCount: 2
            lineHeight: 0.92
        }
    }

    Item {
        visible: root.opens
        anchors.right: parent.right
        width: NihilStyle.s(34)
        height: parent.height
        NIcon {
            anchors.centerIn: parent
            anchors.horizontalCenterOffset: -NihilStyle.s(4)
            text: "chevron_right"
            size: NihilStyle.s(18)
            color: root.ink
        }
        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: root.opened()
        }
    }
}
