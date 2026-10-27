import QtQuick
import qs.services
import qs.modules.common.functions
import qs.modules.waffle.looks

// What the welcome wizard shows with Waffle: its look and its words; the steps are the base ones.
Item {
    visible: false

    readonly property color welcomeSurfaceRaised: Looks.colors.bg0
    readonly property color welcomeSurfaceHigh: Looks.colors.bg1Base
    readonly property color welcomeSurfaceHighest: Looks.colors.bg2Base
    readonly property color welcomeSurfaceRaisedHover: Looks.colors.bg1Hover
    readonly property color welcomeOnSurface: Looks.colors.fg
    readonly property color welcomeOnSurfaceVariant: Looks.colors.subfg
    readonly property color welcomeOutline: Looks.settings.strokeStrong
    readonly property color welcomePrimary: Looks.colors.accent
    readonly property color welcomeOnPrimary: Looks.colors.accentFg
    readonly property color welcomePrimaryContainer: ColorUtils.mix(Looks.colors.bg1Base, Looks.colors.accent, 0.84)
    readonly property color welcomeOnPrimaryContainer: Looks.colors.fg
    readonly property color welcomeSecondary: Looks.colors.accentUnfocused
    readonly property color welcomeSecondaryContainer: Looks.settings.tile
    readonly property color welcomeOnSecondaryContainer: Looks.colors.fg
    readonly property color welcomeTertiary: Looks.colors.accentUnfocused
    readonly property color welcomeTertiaryContainer: Looks.settings.tile
    readonly property color welcomeOnTertiaryContainer: Looks.colors.subfg
    readonly property color welcomeAccentHover: ColorUtils.mix(Looks.colors.bg1Hover, Looks.colors.accent, 0.80)
    readonly property string welcomeFontMain: Looks.fontFamily
    readonly property string welcomeFontTitle: Looks.fontFamily
    readonly property real welcomePanelRadius: Looks.settings.radiusXLarge
    readonly property real welcomeControlRadius: Looks.settings.radiusMedium
    readonly property real welcomeChoiceRadius: Looks.settings.radiusLarge
    readonly property real welcomeCardRadius: Looks.settings.radiusLarge

    readonly property var steps: [
        {
            icon: "tune", title: Translation.tr("Starting point"),
            headline: Translation.tr("Choose your starting setup"),
            subtitle: Translation.tr("Start simple, balanced or with more tools. You can change every module later.")
        },
        {
            icon: "palette", title: Translation.tr("Appearance"),
            headline: Translation.tr("Make it yours"),
            subtitle: Translation.tr("Wallpaper sets the colors across the shell and your apps.")
        },
        {
            icon: "dashboard", title: Translation.tr("Layout"),
            headline: Translation.tr("Arrange the desktop"),
            subtitle: Translation.tr("Choose where the taskbar sits and how it lines up apps.")
        }
    ]
}
