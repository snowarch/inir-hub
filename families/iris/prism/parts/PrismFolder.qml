import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// A group on the shelf, as the B · Carpeta study draws it (his 11-18: "tal cual a la imagen"; 11-17: "no toda la misma
// forma de card"). Two sheets: the front one is the card, its tab at the left carrying the group's name; the back one
// stands behind it, its own tab at the other side, cut from the page's art in one of the desktop's colours, so the art
// shows where the front steps down. What the group holds sets the shape:
//   folder  the two sheets;
//   slip    a short group (a row or two, nothing laid out under them): the front sheet alone, a plain folder;
//   band    a gallery across the page (faces, palettes, pieces): the two sheets, wide.
// The group's name is said once, on the tab, with what it is for under it; a master switch stands at the tab's end.
Item {
    id: root
    // { title, rows }
    property var entry: ({ title: "", rows: [] })
    property string tint: "grey"
    property int turn: 0
    property string flashPath: ""
    property string shape: "folder"
    property bool tabLeft: true
    readonly property string title: String(root.entry?.title ?? "")
    readonly property bool backed: root.shape !== "slip"

    readonly property real r: PrismTheme.dp(22)
    readonly property real padX: PrismTheme.dp(18)
    // The back sheet: its tab stands this far over the rest of its edge. The front sheet starts a little under the
    // back's low edge (a sliver of art over the front's tab) and steps down by its own rise.
    readonly property real backRise: root.backed ? PrismTheme.dp(24) : 0
    readonly property real frontTop: root.backed ? root.backRise + PrismTheme.dp(6) : 0
    readonly property real frontRise: PrismTheme.dp(26)
    readonly property real slope: PrismTheme.dp(46)
    readonly property real bodyTop: root.frontTop + root.frontRise
    // The front tab is as long as the group's name (and its switch), between two fifths and three fifths of the card.
    readonly property real frontTab: Math.round(Math.max(root.width * 0.4, Math.min(root.width * 0.62,
        titleMetrics.advanceWidth + 2 * root.padX + (head.masterSwitch ? PrismTheme.dp(60) : 0) + root.slope * 0.4)))
    TextMetrics { id: titleMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.dp(15); font.weight: Font.DemiBold; text: Translation.tr(root.title) }

    readonly property real headY: root.frontTop + PrismTheme.dp(15)
    readonly property real rowsY: Math.max(root.bodyTop + PrismTheme.dp(6), root.headY + head.implicitHeight + PrismTheme.dp(12))
    implicitHeight: root.rowsY + (rows.rows.length > 0 ? rows.implicitHeight : 0) + PrismTheme.dp(14)

    // The back sheet's art, drawn once offscreen, never shown by itself.
    PrismFlow {
        id: art
        visible: false
        layer.enabled: root.backed
        width: root.width
        height: root.bodyTop + root.r
        tint: root.tint
        turn: root.turn
        seed: 0.23 + root.turn * 0.29
        // The light gathers at the back's tab and dies toward the front's.
        centre: Qt.point(root.tabLeft ? 0.8 : 0.2, 0.15)
        thickness: 0.85
        strength: PrismTheme.light ? 0.75 : 1
        mute: 0.05
    }
    // The back sheet, only where it shows: from its own top edge (its tab at the right) down to the front's, so no art
    // lies under the front even when the front is smoke over glass. Drawn for a tab at the left, mirrored otherwise.
    Shape {
        visible: root.backed
        width: root.width
        height: art.height
        preferredRendererType: Shape.CurveRenderer
        transform: Scale { xScale: root.tabLeft ? 1 : -1; origin.x: root.width / 2 }
        ShapePath {
            fillItem: root.backed ? art : null
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg {
                readonly property real w: root.width
                readonly property real r: root.r
                readonly property real s: root.slope
                readonly property real k: root.backRise
                readonly property real t: w - Math.round(w * (root.shape === "band" ? 0.4 : 0.52))
                readonly property real f: root.frontTop
                readonly property real b: root.bodyTop
                readonly property real tf: root.frontTab
                readonly property real rf: Math.min(r, root.frontRise + 2)
                path: `M 0 ${k + r} Q 0 ${k} ${r} ${k} L ${t - s} ${k} C ${t - s * 0.45} ${k} ${t - s * 0.35} 0 ${t + s * 0.15} 0 `
                    + `L ${w - r} 0 Q ${w} 0 ${w} ${r} L ${w} ${b + r} Q ${w} ${b} ${w - r} ${b} `
                    + `L ${tf + s} ${b} C ${tf + s * 0.45} ${b} ${tf + s * 0.35} ${f} ${tf - s * 0.15} ${f} `
                    + `L ${rf} ${f} Q 0 ${f} 0 ${f + rf} Z`
            }
        }
    }
    PrismSheet {
        y: root.frontTop
        width: root.width
        height: root.height - root.frontTop
        onRight: !root.tabLeft
        tab: root.frontTab
        rise: root.frontRise
        slope: root.slope
        radius: root.r
        fill: PrismTheme.folder
    }

    PrismGroupHead {
        id: head
        x: root.tabLeft ? root.padX : root.width - root.frontTab + root.padX
        y: root.headY
        width: root.frontTab - 2 * root.padX + root.slope * 0.25
        // The name sits in the tab; the line under it is already on the body, so it runs the folder's width.
        lineWidth: root.tabLeft ? root.width - 2 * root.padX : width
        size: PrismTheme.dp(15)
        entry: root.entry
    }
    PrismSection {
        id: rows
        bare: true
        // Narrow on the shelf, a field's control goes under its name; a folder given the row's width lays its rows
        // out as the page card does.
        compact: root.width < PrismTheme.dp(560)
        x: root.padX
        y: root.rowsY
        width: root.width - 2 * root.padX
        title: root.title
        rows: head.on ? head.bodyRows : []
        headlessKey: head.headlessKey
        flashPath: root.flashPath
    }
}
