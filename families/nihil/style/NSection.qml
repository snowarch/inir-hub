import QtQuick

// A group of rows: its name in mono above one flat piece, the rows inside it with no lines between them.
Column {
    id: root

    property string title: ""
    default property alias rows: inner.data

    spacing: NihilStyle.s(8)

    NText {
        visible: root.title.length > 0
        x: NihilStyle.s(14)
        width: root.width - NihilStyle.s(28)
        mono: true
        text: root.title.toUpperCase()
        font.pixelSize: NihilStyle.textSmall
        font.weight: Font.DemiBold
        color: NihilStyle.ink
    }
    Rectangle {
        width: root.width
        height: inner.implicitHeight + NihilStyle.sectionPad * 2
        radius: NihilStyle.cardRadius
        color: NihilStyle.piece
        Column {
            id: inner
            x: NihilStyle.sectionPad
            y: NihilStyle.sectionPad
            width: parent.width - NihilStyle.sectionPad * 2
        }
    }
}
