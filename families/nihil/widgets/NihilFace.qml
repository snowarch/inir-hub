pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.nihil.style

// What every NiHiL face shares: its widget, its size class, its measure (`dp`, the widget's scale), and the ink it
// reads with on the bare wallpaper (`bareInk`), for the faces that stand with no piece under them (the clock).
Item {
    id: root

    required property var widget
    readonly property string size: root.widget.sizeClass
    readonly property bool small: root.size === "small"
    readonly property bool medium: root.size === "medium"
    readonly property bool large: root.size === "large"
    readonly property real k: root.widget.scaleFactor ?? 1
    function dp(px: real): real { return Math.round(px * root.k) }
    readonly property bool live: root.widget.powerActive && root.widget.visible
    // On the wallpaper: dark ink over a light region, light over a dark one.
    readonly property bool onLight: Boolean(root.widget.inkOnLight)
    readonly property color bareInk: root.onLight ? NihilStyle.neutral(NihilStyle.m3.m3onSurface, 0.07)
        : NihilStyle.neutral(NihilStyle.m3.m3surface, 0.97)
    readonly property real radius: root.dp(26)
}
