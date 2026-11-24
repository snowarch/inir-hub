import QtQuick
import QtQuick.Layouts
import "../skin"

// One checkbox row for a group of settings.
Rectangle {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled(bool checked)
    implicitHeight: Math.round(InkSkin.rowHeight * 0.8)
    radius: InkSkin.radius
    color: area.containsMouse && root.enabled ? InkSkin.hover : "transparent"
    opacity: root.enabled ? 1 : 0.45
    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: InkSkin.small
        anchors.rightMargin: InkSkin.small
        spacing: InkSkin.small
        InkGlyph { name: root.checked ? "check_box" : "check_box_outline_blank"; color: root.checked ? InkSkin.accent : InkSkin.muted }
        InkText { Layout.fillWidth: true; text: root.label }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onClicked: root.toggled(!root.checked)
    }
}
