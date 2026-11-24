import QtQuick
import "../skin"

// A small tonal label: a family, a group.
Rectangle {
    id: root
    property string text: ""
    implicitWidth: label.implicitWidth + InkSkin.gap
    implicitHeight: label.implicitHeight + InkSkin.small
    radius: InkSkin.smallRadius
    color: InkSkin.plate
    InkText { id: label; anchors.centerIn: parent; width: Math.min(implicitWidth, root.parent ? root.parent.width - InkSkin.gap : implicitWidth); text: root.text; role: "meta"; color: InkSkin.muted }
}
