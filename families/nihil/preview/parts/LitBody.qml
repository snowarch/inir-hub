pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Effects
import qs.modules.nihil.style

Item {
    id: body
    property color light
    property real restWidth: 0
    property real restHeight: 0
    property real progress: 1
    default property alias content: bodyContent.data
    RectangularShadow {
        offset.x: IrisStyle.shadowThrow
        anchors.fill: bodyPlate
        radius: 0
        offset.y: IrisStyle.shadowThrow
        blur: 0
        color: IrisStyle.shadow
    }
    LitPlate {
        id: bodyPlate
        anchors.fill: parent
        radius: Math.min(IrisStyle.radiusSheet, height / 2)
        light: body.light
    }
    Item {
        id: bodyContent
        readonly property real pad: IrisStyle.concentricPad(IrisStyle.radiusSheet, 14 * IrisStyle.density)
        x: bodyContent.pad
        y: bodyContent.pad
        width: body.restWidth - 2 * bodyContent.pad
        height: body.restHeight - 2 * bodyContent.pad
        opacity: IrisStyle.ramp(body.progress, 0.55, 0.45)
        visible: opacity > 0
    }
}
