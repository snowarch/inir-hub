import QtQuick
import QtQuick.Controls

ScrollBar {
    id: root
    policy: ScrollBar.AsNeeded
    contentItem: Rectangle {
        implicitWidth: Math.round(InkSkin.small * 0.75)
        radius: width / 2
        color: InkSkin.muted
        opacity: root.active ? 0.9 : 0.35
    }
}
