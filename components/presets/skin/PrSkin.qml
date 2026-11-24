pragma Singleton

// The tokens Presets draws with, all taken from the shell's Appearance. Views never name a colour or a size themselves.
import QtQuick
import Quickshell
import qs.modules.common

Singleton {
    id: root

    // Surfaces, from the window outward.
    readonly property color page: Appearance.colors.colLayer2Base
    readonly property color side: Appearance.colors.colLayer1Base
    readonly property color sheet: Appearance.colors.colLayer4Base
    readonly property color plate: Appearance.colors.colLayer3Base
    readonly property color hover: Appearance.colors.colLayer3Hover
    readonly property color edge: Appearance.colors.colOutlineVariant
    readonly property color scrim: Appearance.colors.colScrim

    // Ink.
    readonly property color text: Appearance.colors.colOnSurface
    readonly property color muted: Appearance.colors.colSubtext
    readonly property color accent: Appearance.colors.colPrimary
    readonly property color onAccent: Appearance.colors.colOnPrimary
    readonly property color danger: Appearance.colors.colError
    readonly property color rowOn: Appearance.colors.colSecondaryContainer
    readonly property color rowOnInk: Appearance.colors.colOnSecondaryContainer

    // Shape and spacing.
    readonly property real radius: Appearance.rounding.small
    readonly property real smallRadius: Appearance.rounding.verysmall
    readonly property real cardRadius: Appearance.rounding.normal
    readonly property real small: Appearance.sizes.spacingSmall
    readonly property real gap: Appearance.sizes.spacingMedium
    readonly property real pad: Appearance.sizes.spacingLarge

    // Type; every length that grows with the text is a multiple of body.
    readonly property int body: Appearance.font.pixelSize.small
    readonly property int meta: Appearance.font.pixelSize.smaller
    readonly property int title: Appearance.font.pixelSize.larger
    readonly property int control: Math.round(body * 2.4)
    readonly property int rowHeight: Math.round(body * 3.2)
}
