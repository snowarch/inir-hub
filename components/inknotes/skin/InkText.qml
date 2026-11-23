import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style

// Text in the family's face. role: body, meta, title or mono.
StyledText {
    property string role: "body"
    shouldUseNumberFont: false
    defaultFont: role === "title" ? InkSkin.titleFont : role === "mono" ? InkSkin.monoFont : InkSkin.mainFont
    font.pixelSize: role === "title" ? InkSkin.title : role === "meta" ? InkSkin.meta : InkSkin.body
    font.weight: InkSkin.iris ? IrisStyle.weight(role === "title" ? Font.DemiBold : Font.Normal) : role === "title" ? Font.DemiBold : Font.Normal
    font.variableAxes: InkSkin.variableAxes
    color: InkSkin.text
    elide: Text.ElideRight
}
