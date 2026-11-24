import QtQuick
import qs.modules.common
import qs.modules.common.widgets

// Text at one of four sizes. role: body, meta, title, or label (small, bold, muted: it heads a group).
StyledText {
    property string role: "body"
    readonly property bool heading: role === "title"
    readonly property bool tag: role === "label"
    shouldUseNumberFont: false
    defaultFont: heading ? Appearance.font.family.title : Appearance.font.family.main
    font.pixelSize: heading ? PrSkin.title : role === "meta" ? PrSkin.meta : tag ? PrSkin.meta - 1 : PrSkin.body
    font.weight: heading ? Font.DemiBold : tag ? Font.Bold : Font.Normal
    color: tag ? PrSkin.muted : PrSkin.text
    elide: Text.ElideRight
}
