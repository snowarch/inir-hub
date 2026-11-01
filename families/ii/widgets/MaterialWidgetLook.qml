pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
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

    glassPlates: Appearance.auroraEverywhere && !Appearance.inirEverywhere && !Appearance.zzzEverywhere
    clipInset: Appearance.angelEverywhere || Appearance.inirEverywhere ? 4 : 0
    softDepth: !Appearance.zzzEverywhere
    tileDepth: !Appearance.zzzEverywhere && !Appearance.inirEverywhere && !Appearance.regaliaEverywhere
    flatFaces: Appearance.zzzEverywhere
    tagHover: Appearance.zzzEverywhere ? Appearance.colors.colLayer1Hover : Appearance.colors.colSecondaryContainerHover
    onAccentContainer: Appearance.zzzEverywhere ? Appearance.zzz.onAccent : Appearance.colors.colOnPrimaryContainer
    ornaments: !look.editorial || Appearance.editorial.ornaments
    serifFamily: look.editorial ? Appearance.editorial.serifFamily : "serif"
    cardInset: look.editorial ? Appearance.editorial.inset : 20
    pillRing: Appearance.zzzEverywhere ? Appearance.zzz.hairlineStrong
        : Appearance.inirEverywhere ? Appearance.inir.colBorder : Appearance.angel.colCardBorder
    pillRingWidth: Appearance.zzzEverywhere ? Appearance.zzz.borderThick
        : Appearance.inirEverywhere || Appearance.angelEverywhere ? 1 : 0
    readonly property Component regaliaTile: Component {
        RegaliaPlate {
            radius: parent?.plateRadius ?? 0
            fillColor: parent?.plateFill ?? "transparent"
            inset: Appearance.regalia.surfaceInset
            elevated: true
        }
    }
    tilePlate: Appearance.regaliaEverywhere ? look.regaliaTile : null
    function emphasisWeight(weight: int): int { return look.editorial ? Appearance.editorial.titleWeight : weight }
    function labelTracking(pixelSize: real): real { return Appearance.zzzEverywhere ? Appearance.zzz.tracking : pixelSize * 0.08 }
    // Aurora's and Angel's glass is a tint over the blurred wallpaper: light glass over a dark one is mid grey (2.3:1 with light ink).
    function glassOver(backdrop: color): color {
        if (!look.glassPlates) return Appearance.colors.colLayer0
        return ColorUtils.mix(Appearance.colors.colLayer0Base, backdrop,
            1 - (Appearance.angelEverywhere ? Appearance.angel.overlayOpacity : Appearance.aurora.popupTransparentize))
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
            // colOnLayer1 is on-surface-variant, already the quiet tone: as the main ink every figure on a plate went grey.
            set.onContainer = Appearance.zzzEverywhere ? Appearance.zzz.onBg : c.colOnSurface
        }
        return set
    }
}
