import QtQuick
import qs.modules.iris.style

// Media Corner's own mark, the app icon (icon.svg), wherever the Corner names itself: the places' header, the rail's
// greeting, a hero with nothing to show yet. Decoded at twice its size so it stays sharp at any scale.
Item {
    id: root
    property real size: Math.round(22 * IrisStyle.density)
    implicitWidth: root.size
    implicitHeight: root.size
    Image {
        anchors.fill: parent
        source: Qt.resolvedUrl("../icon.svg")
        sourceSize: Qt.size(root.size * 2, root.size * 2)
        fillMode: Image.PreserveAspectFit
        smooth: true
        mipmap: true
        asynchronous: true
    }
}
