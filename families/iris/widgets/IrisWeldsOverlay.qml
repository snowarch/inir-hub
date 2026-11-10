pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.iris.frame
import qs.modules.iris.style

// What the frame's own window does for the widgets joined to it (IrisWelds). The frame is drawn above the desktop, so
// the lit line along its inner edge crossed every weld: it is taken out where a widget joins. And while the
// compositor shows its overview the desktop zooms away under the frame, so the joined widgets are held here.
Item {
    id: overlay

    required property string output
    // The band is solid matter: a patch of it can stand over its edge line (glass has none to give).
    property bool lined: false
    property color matter: IrisStyle.bodySurface
    readonly property var welds: IrisWelds.on(overlay.output)
    readonly property real line: Math.max(1, IrisStyle.edgeWidth) + 2
    readonly property real round: IrisFrame.cornerRadius

    Repeater {
        model: overlay.welds
        Item {
            id: one
            required property var modelData
            readonly property var weld: one.modelData
            readonly property rect box: one.weld.box
            readonly property var walls: one.weld.walls
            readonly property real past: Math.round(one.weld.fuse * 0.45)
            anchors.fill: parent

            Loader {
                active: one.weld.lent
                sourceComponent: Item {
                    IrisWeldBody { weld: one.weld }
                    Image {
                        x: one.weld.origin.x
                        y: one.weld.origin.y
                        width: one.weld.width
                        height: one.weld.height
                        opacity: one.weld.shown
                        source: one.weld.shot?.url ?? ""
                    }
                }
            }
            // The band's line, taken out between the weld's fillets on each wall it joins; its corner too when the
            // widget sits in one.
            component Patch: Rectangle {
                color: overlay.matter
                visible: overlay.lined && opacity > 0
            }
            component Corner: Patch {
                width: overlay.round + overlay.line
                height: overlay.round + overlay.line
            }
            Corner { opacity: Math.min(one.weld.meltLeft, one.weld.meltTop) * one.weld.cover; x: one.walls.left - overlay.line; y: one.walls.top - overlay.line }
            Corner { opacity: Math.min(one.weld.meltRight, one.weld.meltTop) * one.weld.cover; x: one.walls.right - overlay.round; y: one.walls.top - overlay.line }
            Corner { opacity: Math.min(one.weld.meltLeft, one.weld.meltBottom) * one.weld.cover; x: one.walls.left - overlay.line; y: one.walls.bottom - overlay.round }
            Corner { opacity: Math.min(one.weld.meltRight, one.weld.meltBottom) * one.weld.cover; x: one.walls.right - overlay.round; y: one.walls.bottom - overlay.round }
            Patch {
                opacity: one.weld.meltLeft * one.weld.cover
                x: one.walls.left - overlay.line; width: overlay.line
                y: one.box.y - one.past; height: one.box.height + one.past * 2
            }
            Patch {
                opacity: one.weld.meltRight * one.weld.cover
                x: one.walls.right; width: overlay.line
                y: one.box.y - one.past; height: one.box.height + one.past * 2
            }
            Patch {
                opacity: one.weld.meltTop * one.weld.cover
                y: one.walls.top - overlay.line; height: overlay.line
                x: one.box.x - one.past; width: one.box.width + one.past * 2
            }
            Patch {
                opacity: one.weld.meltBottom * one.weld.cover
                y: one.walls.bottom; height: overlay.line
                x: one.box.x - one.past; width: one.box.width + one.past * 2
            }
        }
    }
}
