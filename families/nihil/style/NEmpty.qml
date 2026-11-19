import QtQuick

// What a page shows while it has nothing: an icon, a line that says so and one that says what will appear.
Column {
    id: root

    property string icon: ""
    property string title: ""
    property string note: ""

    width: NihilStyle.s(340)
    spacing: NihilStyle.s(6)

    NIcon {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: root.icon.length > 0
        text: root.icon
        size: NihilStyle.s(30)
        color: NihilStyle.textTertiary
    }
    Item { width: 1; height: NihilStyle.s(4); visible: root.icon.length > 0 }
    NText {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.title
        font.pixelSize: NihilStyle.textLarge
        font.weight: Font.Medium
    }
    NText {
        width: parent.width
        visible: root.note.length > 0
        horizontalAlignment: Text.AlignHCenter
        text: root.note
        font.pixelSize: NihilStyle.textSmall
        color: NihilStyle.textSecondary
        wrapMode: Text.Wrap
        maximumLineCount: 2
    }
}
