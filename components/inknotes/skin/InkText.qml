import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.style

// Text in the family's face. role: body, meta, title, mono, or label (small bold capitals above a group).
StyledText {
    property string role: "body"
    shouldUseNumberFont: false
    defaultFont: role === "title" ? InkSkin.titleFont : role === "mono" ? InkSkin.monoFont : InkSkin.mainFont
    font.pixelSize: role === "title" ? InkSkin.title : role === "meta" ? InkSkin.meta : role === "label" ? InkSkin.labelSize : InkSkin.body
    font.weight: InkSkin.iris ? IrisStyle.weight(role === "title" ? Font.DemiBold : role === "label" ? Font.Bold : Font.Normal) : role === "title" ? Font.DemiBold : role === "label" ? Font.Bold : Font.Normal
    font.capitalization: role === "label" ? Font.AllUppercase : Font.MixedCase
    font.letterSpacing: role === "label" ? 0.8 : 0
    font.variableAxes: InkSkin.variableAxes
    color: role === "label" ? InkSkin.muted : InkSkin.text
    elide: Text.ElideRight
}
