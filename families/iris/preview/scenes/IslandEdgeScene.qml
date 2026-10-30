pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.iris.style
import qs.modules.iris.frame
import qs.modules.iris.preview
import qs.modules.iris.preview.parts

PreviewScene {
    id: edgeRoot
    // The Island as it stands on this screen, at its own size: its edge, layout, notch, clock, room and bubbles are
    // the ones the rows set, read from the Island itself. A drawn stand-in kept a fixed clock and empty bubbles while
    // the rows changed them (his 10-30: "no coordinan con lo que se cambia").
    readonly property real naturalWidth: Math.round(640 * edgeRoot.d)
    readonly property real naturalHeight: Math.round(320 * edgeRoot.d)
    narrowest: Math.round(200 * edgeRoot.d)
    lowest: Math.round(110 * edgeRoot.d)
    readonly property string edge: IrisFrame.islandEdge
    readonly property string layout: String(edgeRoot.opt("iris.bar.layout", "island"))
    readonly property bool spans: edgeRoot.layout === "full" || (edgeRoot.layout === "menubar" && edgeRoot.edge !== "left" && edgeRoot.edge !== "right")
    readonly property bool notch: edgeRoot.opt("iris.bar.notch", false)
    subject: {
        const g = screen.island, v = screen.view, k = screen.s
        return Qt.rect((g.x - v.x) * k, (g.y - v.y) * k, g.width * k, g.height * k)
    }
    IrisScreenPreview {
        id: screen
        anchors.fill: parent
        radius: 0
        outlined: false
        // Up to half again its size where the stage has room: drawn, not stretched (the wallpaper decodes at the
        // canvas, the field and type draw at it), so it stays sharp.
        maxScale: 1.5
        focusRect: screen.islandReach
    }
    Caption {
        anchors.leftMargin: Math.round((edgeRoot.edge === "left" ? edgeRoot.subject.x + edgeRoot.subject.width : 0) + 14 * edgeRoot.d)
        glyph: ({ top: "vertical_align_top", bottom: "vertical_align_bottom", left: "align_horizontal_left", right: "align_horizontal_right" })[edgeRoot.edge] ?? "pill"
        text: Translation.tr(({ top: "Top edge", bottom: "Bottom edge", left: "Left edge", right: "Right edge" })[edgeRoot.edge] ?? "")
            + " · " + (edgeRoot.layout === "menubar" ? Translation.tr("a menu bar with a notch") : edgeRoot.spans ? Translation.tr("a bar across it") : edgeRoot.notch ? Translation.tr("melts into it") : Translation.tr("floats off it"))
    }
}
