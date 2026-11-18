import QtQuick
import qs.modules.nihil.style
import qs.modules.nihil.components

// The hero's art, printed: a boxed sheet, a screen of dots on its far side, and the specimen card standing on it with
// a hard shadow.
Item {
    id: root

    property rect card: Qt.rect(width * 0.62, height * 0.14, height * 0.72, height * 0.72)
    property real cardRadius: 0
    property real cornerRadius: 0
    property color base: IrisStyle.surfaceOpaque
    property point source: Qt.point(0, 1)
    property point prismAt: Qt.point(0.5, 0.56)
    property real spread: 0.8

    Rectangle {
        anchors.fill: parent
        color: root.base
        border.width: IrisStyle.edgeWidth
        border.color: IrisStyle.text
    }
    IrisDither {
        x: Math.round(root.width * 0.46)
        y: IrisStyle.edgeWidth
        width: root.width - x - IrisStyle.edgeWidth
        height: root.height - IrisStyle.edgeWidth * 2
        ink: IrisStyle.text
        level: 0.38
    }
    Rectangle {
        x: root.card.x + IrisStyle.shadowThrow
        y: root.card.y + IrisStyle.shadowThrow
        width: root.card.width
        height: root.card.height
        color: IrisStyle.text
    }
    Rectangle {
        x: root.card.x
        y: root.card.y
        width: root.card.width
        height: root.card.height
        color: IrisStyle.surfaceOpaque
        border.width: IrisStyle.edgeWidth
        border.color: IrisStyle.text
    }
}
