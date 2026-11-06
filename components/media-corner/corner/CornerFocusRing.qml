import QtQuick
import qs.modules.iris.style

// The keyboard's mark on what it is on: a ring just outside the parent, drawn only while focused.
Rectangle {
    property bool on: false
    visible: on
    anchors.fill: parent
    anchors.margins: -2
    radius: parent.radius !== undefined ? parent.radius + 2 : 0
    color: "transparent"
    border.width: 2
    border.color: IrisStyle.accent
}
