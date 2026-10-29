pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import qs.modules.waffle.looks

// A section header between groups of cards, as Windows 11 Settings draws one: BodyStrong text, 30 px above,
// 6 below (CommunityToolkit's settings page sample). The icon is kept for callers but not drawn: Windows' headers
// carry none, and the cards under them already do.
ColumnLayout {
    id: root
    property string title: ""
    property string icon: ""
    property string description: ""

    Layout.fillWidth: true
    Layout.topMargin: Looks.dp(22)
    Layout.bottomMargin: Looks.dp(2)
    Layout.leftMargin: Looks.dp(1)
    spacing: Looks.dp(2)

    WText {
        Layout.fillWidth: true
        text: root.title
        font.pixelSize: Looks.settings.body
        font.weight: Looks.font.weight.strong
        Accessible.role: Accessible.Heading
    }
    WText {
        visible: root.description !== ""
        Layout.fillWidth: true
        text: root.description
        font.pixelSize: Looks.settings.caption
        font.weight: Looks.font.weight.thin
        color: Looks.colors.subfg
        wrapMode: Text.WordWrap
    }
}
