import QtQuick
import "../skin"

// A small tonal label: a family, a group.
Rectangle {
    id: root
    property string text: ""
    implicitWidth: label.implicitWidth + PrSkin.gap
    implicitHeight: label.implicitHeight + PrSkin.small
    radius: PrSkin.smallRadius
    color: PrSkin.plate
    PrText { id: label; anchors.centerIn: parent; width: Math.min(implicitWidth, root.parent ? root.parent.width - PrSkin.gap : implicitWidth); text: root.text; role: "meta"; color: PrSkin.muted }
}
