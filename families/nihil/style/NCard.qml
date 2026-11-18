import QtQuick
import QtQuick.Effects

// A panel's one piece: flat, rounded, a soft shadow under it so it reads on any wallpaper; its keys sit `pad` in.
Rectangle {
    id: root

    property real pad: NihilStyle.panelPad
    default property alias content: inner.data

    radius: NihilStyle.panelRadius
    color: NihilStyle.piece
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: NihilStyle.shadow
        shadowBlur: 0.7
        shadowVerticalOffset: NihilStyle.s(4)
    }

    // Swallows clicks so one on the card never reaches the panel's dismiss area under it.
    MouseArea { anchors.fill: parent }

    Item {
        id: inner
        anchors.fill: parent
        anchors.margins: root.pad
    }
}
