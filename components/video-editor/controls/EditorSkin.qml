// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.waffle.looks
import "../state"

Singleton {
    readonly property bool iris: Plugins.active === "iris"
    readonly property bool waffle: Plugins.active === "waffle"

    readonly property string look: EditorOptions.style === "prism" || EditorOptions.style === "classic" ? EditorOptions.style : "folio"
    readonly property bool prism: look === "prism"
    readonly property bool classic: look === "classic"
    readonly property bool folio: look === "folio"
    readonly property var looks: [
        { id: "classic", glyph: "view_sidebar", label: "Classic" },
        { id: "folio", glyph: "article", label: "Folio" },
        { id: "prism", glyph: "flare", label: "Prism" }
    ]

    readonly property real d: iris ? IrisStyle.density : 1
    readonly property color solid: iris ? (prism ? IrisStyle.prismSolid : IrisStyle.accentFill) : waffle ? Looks.colors.accent : Appearance.colors.colPrimary
    readonly property color inkOnSolid: iris ? (prism ? IrisStyle.inkOnPrism : IrisStyle.inkOnAccent) : waffle ? Looks.colors.accentFg : Appearance.colors.colOnPrimary
    readonly property color page: iris ? (prism ? IrisStyle.surfaceOpaque : IrisStyle.surface) : waffle ? (prism ? Looks.colors.bg0Opaque : Looks.applyBackgroundTransparency(Looks.colors.bg0)) : (prism ? Appearance.colors.colLayer0Base : Appearance.colors.colSurfaceContainer)
    readonly property color card: iris ? (prism ? IrisStyle.surfaceHighOpaque : IrisStyle.formPlate) : waffle ? (prism ? Looks.colors.bg2Base : Looks.applyContentTransparency(Looks.colors.bg2Base)) : (prism ? Appearance.colors.colSurfaceContainerHigh : Appearance.colors.colLayer2)
    readonly property int cardRadius: Math.round(iris ? (prism ? IrisStyle.radiusCard : IrisStyle.radiusTile) : waffle ? Looks.radius.large : Appearance.rounding.large)
    readonly property color plate: iris ? (prism ? IrisStyle.surfaceHighestOpaque : IrisStyle.fill) : waffle ? Looks.colors.interactiveSurface : Appearance.colors.colSurfaceContainerHighest
    readonly property color edge: iris ? IrisStyle.hairline : waffle ? Looks.colors.bg1Border : Appearance.colors.colLayer0Border
    readonly property int edgeWidth: prism ? 1 : 0
    readonly property color column: iris ? (prism ? IrisStyle.surfaceHighOpaque : IrisStyle.readingSidebar) : card
    readonly property color rowOn: iris ? (prism ? IrisStyle.surfaceHighestOpaque : classic ? IrisStyle.fill : IrisStyle.text) : waffle ? Looks.colors.accent : Appearance.colors.colSecondaryContainer
    readonly property color rowOnInk: iris ? (folio ? IrisStyle.surfaceOpaque : IrisStyle.text) : waffle ? Looks.colors.accentFg : Appearance.colors.colOnSecondaryContainer
    readonly property int columnEdge: folio ? 0 : 1
    readonly property int titleSize: iris ? (prism ? IrisStyle.typeTitleLarge : Math.round(26 * IrisStyle.typeScale)) : waffle ? Looks.font.pixelSize.xlarger : Appearance.font.pixelSize.title // literal: Folio's page title
    readonly property int markSize: iris ? IrisStyle.typeTitleLarge : titleSize
    readonly property int titleWeight: prism ? Font.Bold : Font.DemiBold
    readonly property int sectionSize: iris ? IrisStyle.typeTitle : body
    readonly property real titleTracking: iris ? (prism ? -0.4 : -0.26) : 0 // literal: each mode's display tracking
    readonly property bool cards: !classic

    readonly property string mainFont: iris ? IrisStyle.fontMain : waffle ? Looks.font.family.ui : Appearance.font.family.main
    readonly property string titleFont: iris ? IrisStyle.fontTitle : waffle ? Looks.font.family.ui : Appearance.font.family.title
    readonly property string monoFont: iris ? IrisStyle.fontNumbers : waffle ? Looks.font.family.monospace : Appearance.font.family.numbers
    readonly property int body: iris ? IrisStyle.typeBody : waffle ? Looks.font.pixelSize.large : Appearance.font.pixelSize.small
    readonly property int meta: iris ? IrisStyle.typeMeta : waffle ? Looks.font.pixelSize.normal : Appearance.font.pixelSize.smaller
    readonly property int title: titleSize
    readonly property real small: iris ? IrisStyle.spaceSmall : waffle ? Looks.settings.cardSpacing : Appearance.sizes.spacingSmall
    readonly property real gap: iris ? IrisStyle.cardPad / 2 : waffle ? Looks.settings.cardPadding / 2 : Appearance.sizes.spacingMedium
    readonly property real pad: iris ? IrisStyle.cardPad : waffle ? Looks.settings.cardPadding : Appearance.sizes.spacingLarge
    readonly property real radius: cardRadius
    readonly property real smallRadius: iris ? (folio ? IrisStyle.radiusRow : IrisStyle.radiusSmall) : waffle ? Looks.radius.medium : Appearance.rounding.small

    readonly property var colors: ({
        page: page,
        low: column,
        card: card,
        plate: plate,
        edge: edge,
        text: iris ? IrisStyle.text : waffle ? Looks.colors.fg : Appearance.colors.colOnSurface,
        muted: iris ? IrisStyle.textSecondary : waffle ? Looks.colors.subfg : Appearance.colors.colOnSurfaceVariant,
        accent: solid,
        onAccent: inkOnSolid,
        rowOn: rowOn,
        rowOnInk: rowOnInk,
        scrim: iris ? IrisStyle.veilStrong : waffle ? Looks.colors.shadow : Appearance.colors.colScrim,
        error: iris ? IrisStyle.danger : waffle ? Looks.colors.danger : Appearance.colors.colError
    })
}
