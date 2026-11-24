import QtQuick
import qs.modules.common.widgets

// A Material Symbols icon sized to the text beside it.
MaterialSymbol {
    property string name: ""
    text: name
    iconSize: Math.round(PrSkin.body * 1.25)
    color: PrSkin.text
}
