pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import qs.modules.common

// What a card in Material's sidebars draws with, under every global style: the built-in cards' ink, inner
// plates and radii, resolved once. Offered to hub widgets (their `ii` face, guides/widgets.md) so a widget in the
// sidebar wears the same style as the cards beside it without naming each style.
Singleton {
    // Editorial, Regalia and Cookie reach these through Appearance.colors, which already wears them.
    readonly property color text: Appearance.zzzEverywhere ? Appearance.zzz.ink
        : Appearance.angelEverywhere ? Appearance.angel.colText
        : Appearance.inirEverywhere ? Appearance.inir.colText : Appearance.colors.colOnLayer1
    readonly property color subtext: Appearance.editorialEverywhere ? Appearance.editorial.muted
        : Appearance.regaliaEverywhere ? Appearance.regalia.onMuted
        : Appearance.cookieEverywhere ? Appearance.cookie.inkMuted
        : Appearance.zzzEverywhere ? Appearance.zzz.inkMuted
        : Appearance.angelEverywhere ? Appearance.angel.colTextSecondary
        : Appearance.inirEverywhere ? Appearance.inir.colTextSecondary : Appearance.colors.colSubtext
    readonly property color accent: Appearance.zzzEverywhere ? Appearance.zzz.accent
        : Appearance.angelEverywhere ? Appearance.angel.colPrimary
        : Appearance.inirEverywhere ? Appearance.inir.colPrimary : Appearance.colors.colPrimary
    readonly property color accentInk: Appearance.zzzEverywhere ? Appearance.zzz.onAccent
        : Appearance.angelEverywhere ? Appearance.angel.colOnPrimary
        : Appearance.inirEverywhere ? Appearance.inir.colOnPrimary : Appearance.colors.colOnPrimary
    // A plate inside the card (a row, a chip, a filled shape); the card itself has none.
    readonly property color plate: Appearance.zzzEverywhere ? Appearance.zzz.chrome
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
        : Appearance.inirEverywhere ? Appearance.inir.colLayer2
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
        : Appearance.colors.colLayer2
    readonly property color plateHover: Appearance.zzzEverywhere ? Appearance.zzz.chromeAlt
        : Appearance.angelEverywhere ? Appearance.angel.colGlassCardHover
        : Appearance.inirEverywhere ? Appearance.inir.colLayer2Hover
        : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurfaceHover
        : Appearance.colLayer2Hover
    readonly property real radius: Appearance.angelEverywhere ? Appearance.angel.roundingNormal
        : Appearance.zzzEverywhere ? Appearance.zzz.cardRadius
        : Appearance.inirEverywhere ? Appearance.inir.roundingNormal : Appearance.rounding.normal
    readonly property real radiusSmall: Appearance.editorialEverywhere ? Appearance.rounding.small
        : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
        : Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
        : Appearance.inirEverywhere ? Appearance.inir.roundingSmall : Appearance.rounding.small
    // Inside the card, from its edge to the content, as the built-in cards keep it.
    readonly property int padding: 8
}
