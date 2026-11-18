import QtQuick

// A pill key with a glyph and a word (Bluetooth, Settings, Energy Saver): the glyph first, the word in mono after it,
// both centred; lit in the signal when on.
NButton {
    id: root

    property string label: ""
    property string glyph: ""
    property bool stacked: false

    tone: NihilStyle.pieceRaised

    Row {
        anchors.centerIn: parent
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
            width: Math.min(implicitWidth, root.width - NihilStyle.s(root.glyph.length > 0 ? 48 : 20))
            mono: true
            text: root.label
            font.pixelSize: NihilStyle.textSmall
            color: root.ink
            horizontalAlignment: Text.AlignHCenter
            wrapMode: root.stacked ? Text.WordWrap : Text.NoWrap
            maximumLineCount: 2
            lineHeight: 0.9
        }
    }
}
