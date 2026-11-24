import QtQuick
import QtQuick.Layouts
import "../skin"

// One checkbox row for a group of settings.
Rectangle {
    id: root
    property string label: ""
    property bool checked: false
    signal toggled(bool checked)
    implicitHeight: Math.round(PrSkin.rowHeight * 0.8)
    radius: PrSkin.radius
    color: area.containsMouse && root.enabled ? PrSkin.hover : "transparent"
    opacity: root.enabled ? 1 : 0.45
    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checked: root.checked
    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: PrSkin.small
        anchors.rightMargin: PrSkin.small
        spacing: PrSkin.small
        PrGlyph { name: root.checked ? "check_box" : "check_box_outline_blank"; color: root.checked ? PrSkin.accent : PrSkin.muted }
        PrText { Layout.fillWidth: true; text: root.label }
    }
    MouseArea {
        id: area
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onClicked: root.toggled(!root.checked)
    }
}
