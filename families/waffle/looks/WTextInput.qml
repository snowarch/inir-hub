import QtQuick
import qs.modules.common.widgets
import QtQuick.Controls

TextInput {
    cursorDelegate: TextCursor { accent: Looks.colors.accent }
    id: root
    renderType: Text.NativeRendering
    verticalAlignment: Text.AlignVCenter
    color: Looks.colors.fg

    font {
        hintingPreference: Font.PreferFullHinting
        family: Looks.font.family.ui
        pixelSize: Looks.font.pixelSize.large
        weight: Looks.font.weight.regular
    }

    selectionColor: Looks.colors.selection
}
