import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.prism.core

// A Material Symbol in Prism's ink.
MaterialSymbol {
    property bool filled: false
    iconSize: PrismTheme.dp(18)
    fill: filled ? 1 : 0
    color: PrismTheme.ink
}
