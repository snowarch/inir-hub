import QtQuick
import QtQuick.Controls

ScrollBar {
    id: bar
    policy: ScrollBar.AsNeeded
    contentItem: Rectangle {
        implicitWidth: Math.round(PrSkin.small / 2)
        radius: width / 2
        color: PrSkin.muted
        opacity: bar.active ? 0.9 : 0.3
    }
}
