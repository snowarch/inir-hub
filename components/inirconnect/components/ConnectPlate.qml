pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.components
import "../state"

Item {
    id: root

    property color color: "transparent"
    property real radius: 0
    property bool lit: false
    default property alias content: host.data

    Loader {
        anchors.fill: parent
        active: ConnectStyle.isIris
        sourceComponent: Component {
            IrisPlate {
                color: root.color
                radius: root.radius
                lit: root.lit
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: !ConnectStyle.isIris
        radius: root.radius
        color: root.color
        border.width: root.color.a > 0 ? 1 : 0
        border.color: ConnectStyle.plateEdge
    }

    Item {
        id: host
        anchors.fill: parent
    }
}
