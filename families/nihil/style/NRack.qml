import QtQuick
import QtQuick.Effects

// A block of tiles: no plate of its own, only one soft shadow under the whole shape, and a click on a seam stays inside.
Item {
    id: root
    default property alias content: inner.data

    MouseArea { anchors.fill: parent }

    Item {
        id: inner
        anchors.fill: parent
        layer.enabled: true
        layer.effect: MultiEffect {
            shadowEnabled: true
            shadowColor: NihilStyle.shadow
            shadowBlur: 0.7
            shadowVerticalOffset: NihilStyle.s(6)
        }
    }
}
