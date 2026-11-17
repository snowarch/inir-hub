// SPDX-License-Identifier: GPL-3.0-only
import QtQuick
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.waffle.looks

StyledText {
    property string role: "body"
    shouldUseNumberFont: false
    defaultFont: role === "title" ? EditorSkin.titleFont : role === "mono" ? EditorSkin.monoFont : EditorSkin.mainFont
    font.pixelSize: role === "title" ? EditorSkin.title : role === "meta" || role === "mono" ? EditorSkin.meta : EditorSkin.body
    font.weight: EditorSkin.iris ? IrisStyle.weight(role === "title" ? Font.DemiBold : Font.Normal) : role === "title" ? Font.Bold : Font.Normal
    font.variableAxes: EditorSkin.iris ? ({}) : EditorSkin.waffle ? Looks.font.variableAxes.ui : Appearance.font.variableAxes.main
    color: EditorSkin.colors.text
}
