pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.shared.background.widgets

// Desktop widgets in Material: what each global style changes on them.
WidgetLook {
    id: look

    editorial: Appearance.editorialEverywhere
    readonly property bool _island: !Appearance.zzzEverywhere && !Appearance.cookieEverywhere
        && !Appearance.angelEverywhere && !Appearance.auroraEverywhere && !Appearance.inirEverywhere
        && (Config.options?.background?.widgets?.style ?? "panel") === "island"

    metaCapitalization: Appearance.editorialEverywhere ? Font.MixedCase : Font.AllUppercase
    rowRadius: Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
        : Appearance.regaliaEverywhere ? Appearance.regalia.controlRadius : Appearance.rounding.small
    chipEdge: Appearance.editorialEverywhere ? 1 : 0
    chipEdgeColor: Appearance.editorialEverywhere ? Appearance.editorial.edge : "transparent"
    function chipRadius(height: real): real {
        return Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
            : Appearance.regaliaEverywhere ? Appearance.regalia.controlRadius
            : Appearance.editorialEverywhere ? Appearance.rounding.small
            : Appearance.angelEverywhere ? Appearance.angel.roundingSmall
            : height / 2
    }
    function chipInk(selected: bool): color {
        return Appearance.zzzEverywhere ? (selected ? Appearance.zzz.onSticker : Appearance.zzz.ink)
            : Appearance.regaliaEverywhere ? (selected ? Appearance.regalia.primaryPlateInk : Appearance.regalia.onColor)
            : selected ? Appearance.colors.colOnPrimary : Appearance.colors.colOnLayer2
    }
    function chipFill(selected: bool, hovered: bool): color {
        if (selected && Appearance.zzzEverywhere) return Appearance.zzz.sticker
        if (selected && Appearance.regaliaEverywhere) return Appearance.regalia.primaryPlate
        return selected ? (hovered ? Appearance.colors.colPrimaryHover : Appearance.colors.colPrimary)
            : ColorUtils.applyAlpha(Appearance.colors.colOnLayer2, hovered ? 0.1 : 0.055)
    }

    function blurAvailable(widget: var): bool {
        return Appearance.effectsEnabled && (Appearance.angelEverywhere
            || (Appearance.auroraEverywhere && !Appearance.inirEverywhere)
            || (look._island && (Appearance.island?.glass ?? true) && (Appearance.island?.opacity ?? 1) < 0.999))
    }
    function titleFamily(widget: var): string { return look.editorial ? Appearance.editorial.displayFamily : Appearance.font.family.main }
    function titleWeight(widget: var): int { return look.editorial ? Appearance.editorial.titleWeight : Font.DemiBold }
    function titleTracking(widget: var): real { return look.editorial ? Appearance.editorial.titleTracking : 0 }
    function titleScale(widget: var): real { return look.editorial ? Appearance.editorial.titleScale : 1 }
    function spacingScale(widget: var): real { return look.editorial ? Appearance.editorial.spacing : 1 }
    function labelWeight(widget: var): int { return look.editorial ? Appearance.editorial.labelWeight : Font.Medium }
    function metadataTracking(widget: var): real { return look.editorial ? Appearance.editorial.metadataTracking : 0 }
    function controlRadius(widget: var): real { return look.editorial ? Appearance.rounding.small : Appearance.rounding.normal }
    function cardRadius(widget: var): real {
        return look.editorial ? Appearance.editorial.radius
            : Appearance.zzzEverywhere ? Appearance.zzz.controlRadius
            : Appearance.cookieEverywhere ? Appearance.cookie.roundLarge
            : Appearance.angelEverywhere ? Appearance.angel.roundingNormal
            : Appearance.inirEverywhere ? Appearance.inir.roundingNormal
            : Appearance.rounding.extralarge
    }

    function semanticSet(widget: var, role: string): var {
        const set = look.plainSet(widget, role)
        const c = Appearance.colors
        if (role === "signal") {
            if (Qt.colorEqual(set.color, c.colError))
                set.color = Appearance.zzzEverywhere ? Appearance.zzz.signal : Appearance.inirEverywhere ? Appearance.inir.colError : c.colError
            if (Appearance.zzzEverywhere) set.onColor = Appearance.zzz.onSignal
        } else if (role === "surface") {
            set.container = Appearance.zzzEverywhere ? Appearance.zzz.chrome
                : Appearance.cookieEverywhere ? c.colLayer2
                : Appearance.angelEverywhere ? Appearance.angel.colGlassCard
                : Appearance.inirEverywhere ? Appearance.inir.colLayer1
                : Appearance.auroraEverywhere ? Appearance.aurora.colSubSurface
                : c.colLayer1
            set.onContainer = Appearance.zzzEverywhere ? Appearance.zzz.onBg
                : Appearance.cookieEverywhere ? Appearance.cookie.onColor
                : c.colOnLayer1
        }
        return set
    }
}
