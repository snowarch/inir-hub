import QtQuick
import qs.services

// A key for what cannot be taken back: the first tap lights it and asks, the second does it, and left alone it goes
// back to rest.
NButton {
    id: root

    property string label: ""
    property string glyph: ""
    property string askLabel: Translation.tr("Sure?")
    property bool armed: false
    signal confirmed()

    implicitWidth: line.implicitWidth + NihilStyle.s(30)
    implicitHeight: NihilStyle.s(36)
    tone: NihilStyle.pieceRaised
    lit: root.armed
    Accessible.role: Accessible.Button
    Accessible.name: word.text

    onClicked: {
        if (!root.armed) { root.armed = true; return }
        root.armed = false
        root.confirmed()
    }
    Timer { running: root.armed; interval: 3500; onTriggered: root.armed = false }

    Row {
        id: line
        anchors.centerIn: parent
        spacing: NihilStyle.s(7)
        NIcon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.glyph.length > 0
            text: root.glyph
            size: NihilStyle.s(16)
            color: root.ink
        }
        NText {
            id: word
            anchors.verticalCenter: parent.verticalCenter
            figures: true
            text: (root.armed ? root.askLabel : root.label).toUpperCase()
            font.pixelSize: NihilStyle.textSmall
            color: root.ink
        }
    }
}
