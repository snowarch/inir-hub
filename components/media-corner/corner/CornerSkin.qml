pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.modules.iris.style
import "../state"

// The one difference between Normal and Prism: how things look and where they sit. Every feature is in both; a view
// asks the skin for its solids, plates and edges and never branches on the style for what it does.
// Each style follows iRiS's Settings in the mode of the same spirit: Normal is Settings' Folio (two columns, the search
// over the page, a light pill for the place you are in, tiles and grouped rows on reading plates); Prism is Settings'
// Prism (three columns, near-black plates, one white solid for what is chosen, hairlines on every edge).
Singleton {
    readonly property bool prism: CornerState.options.style === "prism"
    readonly property real d: IrisStyle.density
    // What is chosen or the main action: a white solid in Prism, the accent in Normal.
    readonly property color solid: prism ? IrisStyle.prismSolid : IrisStyle.accentFill
    readonly property color inkOnSolid: prism ? IrisStyle.inkOnPrism : IrisStyle.inkOnAccent
    // The page itself: opaque in Prism, as Settings is; Normal keeps iRiS's glass.
    readonly property color page: prism ? IrisStyle.surfaceOpaque : IrisStyle.surface
    // A card on the page, a plate inside a card, and the edge they share.
    readonly property color card: prism ? IrisStyle.surfaceHighOpaque : IrisStyle.formPlate
    readonly property int cardRadius: prism ? IrisStyle.radiusCard : IrisStyle.radiusTile
    readonly property color plate: prism ? IrisStyle.surfaceHighestOpaque : IrisStyle.fill
    readonly property color edge: IrisStyle.hairline
    readonly property int edgeWidth: prism ? 1 : 0
    // The side columns: the places on the left and Yours on the right.
    readonly property color column: prism ? IrisStyle.surfaceHighOpaque : IrisStyle.readingSidebar
    // A list row picked: a solid plate in Prism; in Normal, Folio's light pill with dark ink.
    readonly property color rowOn: prism ? IrisStyle.surfaceHighestOpaque : IrisStyle.text
    readonly property color rowOnInk: prism ? IrisStyle.text : IrisStyle.surfaceOpaque
    // Headings: an eyebrow over a bold title, as Settings writes them.
    readonly property int titleSize: prism ? IrisStyle.typeTitleLarge : Math.round(26 * IrisStyle.typeScale) // literal: Folio's page title
    readonly property int titleWeight: prism ? Font.Bold : Font.DemiBold
    readonly property int sectionSize: IrisStyle.typeTitle
    readonly property real titleTracking: prism ? -0.4 : -0.26 // literal: each mode's display tracking
}
