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
        source: String(root.option("source", "auto"))
        file: String(root.option("file", ""))
        word: String(root.option("word", "iNiR"))
        lookName: String(root.option("look", "signal"))
        glyphPixel: Math.max(1, Number(root.option("glyph", 1)))
        glowAmount: Number(root.option("glow", 100)) / 100
        growIn: root.option("grow", true) === true
        radius: Looks.radius.medium
        accent: Looks.colors.accent
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
        visible: view.title.length > 0
        x: view.x
        y: view.y + view.height + Looks.dp(8)
        width: view.width
        text: view.artist.length > 0 ? view.title + "  ·  " + view.artist : view.title
        elide: Text.ElideRight
        font.pixelSize: Looks.font.pixelSize.normal
        color: Looks.colors.subfg
    }
}
