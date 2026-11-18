import QtQuick
import QtQuick.Effects
import qs.modules.nihil.style

// A floating body's printed shadow: a solid block of ink, thrown down and to the right. Readers place it over the body;
// whatever softness they ask for is not drawn.
Item {
    id: root

    property real radius: 0
    property real blur: 0
    property real spread: 0
    property vector2d offset: Qt.vector2d(0, 0)
    property color color: IrisStyle.shadow

    Rectangle {
        x: IrisStyle.shadowThrow
        y: IrisStyle.shadowThrow
        width: root.width
        height: root.height
        color: IrisStyle.shadow
    }
}
