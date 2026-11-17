// SPDX-License-Identifier: GPL-3.0-only
pragma Singleton
import QtQml
import qs.services
import qs.modules.common
import qs.modules.iris.style
import qs.modules.waffle.looks

QtObject {
    readonly property bool iris: Plugins.active === "iris"
    readonly property bool waffle: Plugins.active === "waffle"
    readonly property string mainFont: iris ? IrisStyle.fontMain : waffle ? Looks.font.family.ui : Appearance.font.family.main
    readonly property string titleFont: iris ? IrisStyle.fontTitle : waffle ? Looks.font.family.ui : Appearance.font.family.title
    readonly property string monoFont: iris ? IrisStyle.fontNumbers : waffle ? Looks.font.family.monospace : Appearance.font.family.numbers
    readonly property int body: iris ? IrisStyle.typeBody : waffle ? Looks.font.pixelSize.large : Appearance.font.pixelSize.small
    readonly property int meta: iris ? IrisStyle.typeMeta : waffle ? Looks.font.pixelSize.normal : Appearance.font.pixelSize.smaller
    readonly property int title: iris ? IrisStyle.typeTitleLarge : waffle ? Looks.font.pixelSize.xlarger : Appearance.font.pixelSize.title
    readonly property real small: iris ? IrisStyle.spaceSmall : waffle ? Looks.settings.cardSpacing : Appearance.sizes.spacingSmall
    readonly property real gap: iris ? IrisStyle.cardPad / 2 : waffle ? Looks.settings.cardPadding / 2 : Appearance.sizes.spacingMedium
    readonly property real pad: iris ? IrisStyle.cardPad : waffle ? Looks.settings.cardPadding : Appearance.sizes.spacingLarge
    readonly property real radius: iris ? IrisStyle.radiusTile : waffle ? Looks.radius.large : Appearance.rounding.large
    readonly property real smallRadius: iris ? IrisStyle.radiusSmall : waffle ? Looks.radius.medium : Appearance.rounding.small
    readonly property var colors: iris ? {
        page: IrisStyle.surfaceOpaque, low: IrisStyle.surfaceHighOpaque, card: IrisStyle.formPlate, plate: IrisStyle.fill,
        text: IrisStyle.text, muted: IrisStyle.textSecondary, accent: IrisStyle.accentFill, onAccent: IrisStyle.inkOnAccent,
        scrim: IrisStyle.veilStrong, error: IrisStyle.danger,
    } : waffle ? {
        page: Looks.colors.bg0Opaque, low: Looks.colors.bg1Base, card: Looks.colors.bg2Base, plate: Looks.colors.interactiveSurface,
        text: Looks.colors.fg, muted: Looks.colors.subfg, accent: Looks.colors.accent, onAccent: Looks.colors.accentFg,
        scrim: Looks.colors.shadow, error: Looks.colors.danger,
    } : {
        page: Appearance.colors.colSurfaceContainer, low: Appearance.colors.colSurfaceContainerLow,
        card: Appearance.colors.colSurfaceContainerHigh, plate: Appearance.colors.colSurfaceContainerHighest,
        text: Appearance.colors.colOnSurface, muted: Appearance.colors.colOnSurfaceVariant,
        accent: Appearance.colors.colPrimary, onAccent: Appearance.colors.colOnPrimary,
        scrim: Appearance.colors.colScrim, error: Appearance.colors.colError,
    }
}
