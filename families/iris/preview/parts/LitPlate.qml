pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

Rectangle {
    id: lit
    property color light: IrisStyle.wallpaperLight
    color: IrisStyle.bodySurface
    border.width: IrisStyle.rim.a > 0 ? 1 : 0
    border.color: IrisStyle.rim
    // A chamfered Design (AIRISU) cuts the body by its die, so a preview wears the same 45° corners as the shell.
    IrisGlassEdge { anchors.fill: parent; z: 10; visible: IrisStyle.edgeLit && shown; radius: parent.radius }
    IrisLightWash {
        anchors.fill: parent
        radius: lit.radius
        light: lit.light
    }
}
