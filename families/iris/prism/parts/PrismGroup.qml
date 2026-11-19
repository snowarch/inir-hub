import QtQuick
import QtQuick.Shapes
import qs.services
import qs.modules.iris.prism.core
import qs.modules.iris.prism.model
import qs.modules.iris.prism.fx
import qs.modules.iris.prism.controls

// A group of a page as a folder (B · Carpeta, his 11-17 pick, the factory look): the front sheet carries the group's
// name on its tab, what the group is for under it and its master switch at the tab's end; behind it a back sheet cut
// from the page's art in the desktop's colours shows where the front steps down. A short group (two rows or fewer) is
// the front sheet alone. Off, the group still shows what it holds, dimmed and still, so turning it on moves nothing.
// A card made of several one-row groups (PrismShelf.cards) lists them as rows under its band's name, or under none.
Item {
    id: root
    // { title, rows, titles }
    property var entry: ({ title: "", rows: [] })
    property string flashPath: ""
    // The page's art colours, turned per folder so neighbours never lead with one colour.
    property string tint: "grey"
    property int turn: 0
    readonly property string title: String(root.entry?.title ?? "")
    // Every group this card holds: a search for one of them lands here.
    readonly property var titles: Array.from(root.entry?.titles ?? [root.title])

    readonly property bool headed: root.title.length > 0
    // A card standing beside another on its line wears its back like its neighbour, so both fronts step down together.
    property bool lined: false
    readonly property bool backed: root.headed && (Array.from(root.entry?.rows ?? []).length > 2 || root.lined)
    readonly property var bodyRows: root.headed ? head.bodyRows : Array.from(root.entry?.rows ?? [])

    readonly property real r: PrismTheme.cardRadius
    readonly property real pad: PrismTheme.dp(20)
    // The back sheet's tab stands this far over the rest of its edge; the front starts a little under the back's low
    // edge and steps down by its own rise.
    readonly property real backRise: root.backed ? PrismTheme.dp(22) : 0
    readonly property real frontTop: root.backed ? root.backRise + PrismTheme.dp(6) : 0
    readonly property real frontRise: PrismTheme.dp(24)
    readonly property real slope: PrismTheme.dp(44)
    readonly property real bodyTop: root.frontTop + root.frontRise
    // The front tab is as long as the group's name (and its switch), between two fifths and two thirds of the card; a
    // card half a line wide lets it run to four fifths, so a name and its switch keep one line.
    readonly property real frontTab: Math.round(Math.max(root.width * 0.42, Math.min(root.width * (root.width < PrismTheme.dp(420) ? 0.82 : 0.66),
        titleMetrics.advanceWidth + 2 * root.pad + (head.masterSwitch ? PrismTheme.dp(64) : 0) + root.slope * 0.2)))
    TextMetrics { id: titleMetrics; font.family: PrismTheme.fontMain; font.pixelSize: PrismTheme.head; font.weight: Font.DemiBold; text: Translation.tr(root.title) }

    readonly property real headY: root.frontTop + PrismTheme.dp(16)
    readonly property real rowsY: root.headed ? Math.max(root.bodyTop + PrismTheme.dp(8), root.headY + head.implicitHeight + PrismTheme.dp(10))
        : PrismTheme.dp(6)
    implicitHeight: root.rowsY + (root.bodyRows.length > 0 ? rows.implicitHeight + PrismTheme.dp(10) : PrismTheme.dp(12))

    // The back sheet's art, drawn once offscreen, never shown by itself. Layered for every named card, not only a backed
    // one: a card that comes to stand beside another (`lined`) takes its back after it was made, and a fill item that
    // turns into a texture only then is refused by the Shape ("Fill item is not texture provider").
    PrismFlow {
        id: art
        visible: false
        layer.enabled: root.headed
        width: root.width
        height: root.bodyTop + root.r
        tint: root.tint
        turn: root.turn
        seed: 0.23 + root.turn * 0.29
        // The light gathers at the back's tab and dies toward the front's.
        centre: Qt.point(0.8, 0.15)
        thickness: 0.85
        strength: PrismTheme.light ? 0.75 : 1
        mute: 0.05
    }
    // The back sheet, only where it shows: its own top edge (its tab at the right) down to the front's edge.
    Shape {
        visible: root.backed
        width: root.width
        height: art.height
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
            fillItem: root.headed ? art : null
            strokeColor: "transparent"
            strokeWidth: -1
            PathSvg {
                readonly property real w: root.width
                readonly property real r: root.r
                readonly property real s: root.slope
                readonly property real k: root.backRise
                readonly property real t: w - Math.round(w * 0.52)
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
    // The front sheet: a tab for a named group, a plain card for rows gathered under no name.
    PrismSheet {
        visible: root.headed
        y: root.frontTop
        width: root.width
        height: root.height - root.frontTop
        tab: root.frontTab
        rise: root.frontRise
        slope: root.slope
        radius: root.r
        fill: PrismTheme.card
    }
    Rectangle {
        visible: !root.headed
        anchors.fill: parent
        radius: root.r
        color: PrismTheme.card
    }

    PrismGroupHead {
        id: head
        visible: root.headed
        x: root.pad
        y: root.headY
        // Short of where the tab slopes down: the master switch stands on its flat top.
        width: root.frontTab - 2 * root.pad - root.slope * 0.2
        // The name sits in the tab; the line under it is already on the body, so it runs the folder's width.
        lineWidth: root.width - 2 * root.pad
        size: PrismTheme.head
        entry: root.entry
    }
    PrismSection {
        id: rows
        // Narrow, a field's control goes under its name.
        compact: root.width < PrismTheme.dp(520)
        x: root.pad
        y: root.rowsY
        width: root.width - 2 * root.pad
        title: root.title
        rows: root.bodyRows
        headlessKey: root.headed ? head.headlessKey : ""
        enabled: head.on
        opacity: head.on ? 1 : 0.38
        Behavior on opacity { NumberAnimation { duration: PrismTheme.ms(200); easing.type: Easing.OutCubic } }
        flashPath: root.flashPath
    }
}
