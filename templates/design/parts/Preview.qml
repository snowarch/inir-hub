import QtQuick
import qs.modules.iris.style

// The Design's picture in Settings › Style › Design: what it is at a glance, in its own colours whatever is worn (so
// they are literals here, and only here), on the forms it gives iRiS.
Rectangle {
    id: root
    readonly property real u: height / 100
    color: "#101114" // literal: the Design's own paper in its picture

    Rectangle {
        width: 64 * root.u
        height: 13 * root.u
        x: (root.width - width) / 2
        y: -1
        radius: 5 * root.u
        color: "#000000" // literal: the Design's Island in its picture
    }
    Rectangle {
        x: 18 * root.u
        y: 24 * root.u
        width: root.width - 36 * root.u
        height: root.height - 34 * root.u
        radius: 4 * root.u
        color: "#1c1d22" // literal: a panel in the Design's own colour
        border.width: Math.max(1, IrisStyle.devicePx)
        border.color: "#3a3c44" // literal: the Design's edge in its picture
    }
}
