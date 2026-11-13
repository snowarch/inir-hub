pragma ComponentBehavior: Bound

// The Waffle face: the same plate as a card in the Widgets panel. The panel draws the card; this lays out inside.

import QtQuick
import qs.services
import qs.modules.waffle.looks

Item {
    id: root

    // Given by the panel.
    property string waffleSlot: ""

    function option(key: string, fallback: var): var {
        return CustomWidgets.getConfigValue("afterglyph", key, fallback)
    }

    implicitHeight: view.height + (named.visible ? named.implicitHeight + Looks.dp(8) : 0) + Looks.dp(32)

    AfterglyphView {
        id: view
        x: Looks.dp(16)
        y: Looks.dp(16)
        width: root.width - Looks.dp(32)
        height: Math.round(width / Math.max(1, view.aspect))
        plate: root.option("plate", true) === true
        radius: Looks.radius.medium
        theme: [Qt.darker(Looks.colors.accent, 2.2), Looks.colors.accent, Qt.lighter(Looks.colors.accent, 1.7), Looks.colors.accent]
        live: root.visible
    }

    WText {
        anchors.fill: view
        anchors.margins: Looks.dp(12)
        visible: view.message.length > 0 && !view.drawn
        text: view.message
        wrapMode: Text.WordWrap
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: Looks.colors.subfg
    }

    WText {
        id: named
        visible: view.name.length > 0 && root.option("caption", false) === true
        x: view.x
        y: view.y + view.height + Looks.dp(8)
        width: view.width
        text: view.name
        elide: Text.ElideRight
        font.pixelSize: Looks.font.pixelSize.normal
        color: Looks.colors.subfg
    }
}
