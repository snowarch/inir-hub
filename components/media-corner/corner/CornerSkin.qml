pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.iris.style
import "../state"

// The one difference between the styles: how things look and where they sit. Every feature is in each; a view asks the
// skin for its solids, plates and edges and never branches on the style for what it does.
// Each style is based on iRiS's Settings in the layout of the same name:
// Classic: the places on a card with the search on top and a tinted glyph each; the page's name over the page.
// Folio: the places down the side under captions, the one you are in on a light pill; the search over the page.
// Classic and Folio share the page itself: tiles and grouped rows on reading plates.
// Prism: three columns, near-black plates, one white solid for what is chosen, hairlines on every edge.
Singleton {
    // "normal" was Folio's name before Classic came; nothing chosen yet wears Folio.
    readonly property string look: CornerState.options.style === "prism" || CornerState.options.style === "classic" ? CornerState.options.style : "folio"
    readonly property bool prism: look === "prism"
    readonly property bool classic: look === "classic"
    readonly property bool folio: look === "folio"
    readonly property var looks: [{ id: "classic", glyph: "view_sidebar", label: "Classic" }, { id: "folio", glyph: "article", label: "Folio" },
        { id: "prism", glyph: "flare", label: "Prism" }]
    readonly property real d: IrisStyle.density
    // What is chosen or the main action: a white solid in Prism, the accent in Classic and Folio.
    readonly property color solid: prism ? IrisStyle.prismSolid : IrisStyle.accentFill
    readonly property color inkOnSolid: prism ? IrisStyle.inkOnPrism : IrisStyle.inkOnAccent
    // The page itself: opaque in Prism, as Settings is; Classic and Folio keep iRiS's glass.
    readonly property color page: prism ? IrisStyle.surfaceOpaque : IrisStyle.surface
    // A card on the page, a plate inside a card, and the edge they share.
    readonly property color card: prism ? IrisStyle.surfaceHighOpaque : IrisStyle.formPlate
    readonly property int cardRadius: prism ? IrisStyle.radiusCard : IrisStyle.radiusTile
    readonly property color plate: prism ? IrisStyle.surfaceHighestOpaque : IrisStyle.fill
    readonly property color edge: IrisStyle.hairline
    readonly property int edgeWidth: prism ? 1 : 0
    // The side columns: the places on the left and Yours on the right.
    readonly property color column: prism ? IrisStyle.surfaceHighOpaque : IrisStyle.readingSidebar
    // A list row picked: a solid plate in Prism; Folio's light pill with dark ink; Classic's quiet fill.
    readonly property color rowOn: prism ? IrisStyle.surfaceHighestOpaque : classic ? IrisStyle.fill : IrisStyle.text
    readonly property color rowOnInk: folio ? IrisStyle.surfaceOpaque : IrisStyle.text
    // The places column's edge: Classic's and Prism's are cards, Folio's is the window's side.
    readonly property int columnEdge: folio ? 0 : 1
    // Headings: an eyebrow over a bold title, as Settings writes them.
    readonly property int titleSize: prism ? IrisStyle.typeTitleLarge : Math.round(26 * IrisStyle.typeScale) // literal: Folio's page title
    readonly property int titleWeight: prism ? Font.Bold : Font.DemiBold
    readonly property int sectionSize: IrisStyle.typeTitle
    readonly property real titleTracking: prism ? -0.4 : -0.26 // literal: each mode's display tracking
}
