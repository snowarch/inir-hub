import QtQuick
import qs.modules.iris.prism.core
import qs.modules.iris.prism.controls

// The reference's two-line head: a small grey word over a bold title, and "See all" on the right when there is more.
Item {
    id: root
    property string eyebrow: ""
    property string title: ""
    property string link: ""
    // Said at the right when there is no link: a figure, never pressed.
    property string note: ""
    property real titleSize: PrismTheme.title
    signal linkClicked()

    implicitHeight: column.implicitHeight
    Column {
        id: column
        width: parent.width - (more.visible ? more.width + PrismTheme.dp(12) : 0) - (figure.visible ? figure.width + PrismTheme.dp(12) : 0)
        spacing: PrismTheme.dp(2)
        PrismText {
            width: parent.width
            visible: root.eyebrow.length > 0
            text: root.eyebrow
            color: PrismTheme.ink2
            font.pixelSize: PrismTheme.body
        }
        PrismText {
            width: parent.width
            text: root.title
            font.pixelSize: root.titleSize
            font.weight: Font.Bold
            font.letterSpacing: -0.4
        }
    }
    PrismText {
        id: more
        visible: root.link.length > 0
        anchors.right: parent.right
        anchors.bottom: column.bottom
        anchors.bottomMargin: PrismTheme.dp(4)
        text: root.link
        color: linkArea.containsMouse ? PrismTheme.ink : PrismTheme.ink2
        font.pixelSize: PrismTheme.small
        MouseArea {
            id: linkArea
            anchors.fill: parent
            anchors.margins: -PrismTheme.dp(6)
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.linkClicked()
        }
    }
    PrismText {
        id: figure
        visible: root.link.length === 0 && root.note.length > 0
        anchors.right: parent.right
        anchors.bottom: column.bottom
        anchors.bottomMargin: PrismTheme.dp(4)
        text: root.note
        figures: true
        color: PrismTheme.ink3
        font.pixelSize: PrismTheme.small
    }
}
