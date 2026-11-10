pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common.widgets
import qs.modules.iris.frame
import qs.modules.iris.style

// Where the frame's window keeps the desktop widgets joined to it (IrisWelds): they move in here, over the bodies the
// frame's field draws for them, and a tucked one leaves its tab with its glyph and a place to point at.
Item {
    id: overlay

    required property string output
    readonly property var welds: IrisWelds.on(overlay.output)
    // What of this window takes the pointer for them.
    readonly property var hitRects: overlay.welds.map(weld => weld.box)

    Item { id: host; anchors.fill: parent }
    Component.onCompleted: IrisWelds.lend(overlay.output, host)
    Component.onDestruction: IrisWelds.lend(overlay.output, null)
    onOutputChanged: IrisWelds.lend(overlay.output, host)

    Repeater {
        model: overlay.welds
        Item {
            id: one
            required property var modelData
            readonly property var weld: one.modelData
            x: one.weld.box.x
            y: one.weld.box.y
            width: one.weld.box.width
            height: one.weld.box.height
            HoverHandler {
                enabled: one.weld.stows
                onHoveredChanged: one.weld.tabPointed = hovered
            }
            MaterialSymbol {
                anchors.centerIn: parent
                text: one.weld.glyph
                iconSize: Math.round(18 * IrisStyle.density)
                color: IrisStyle.textSecondary
                opacity: Math.max(0, one.weld.tuck * 2 - 1)
                visible: opacity > 0
            }
        }
    }
}
