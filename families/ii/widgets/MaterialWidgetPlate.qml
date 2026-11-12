import QtQuick
import Quickshell
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.shared.background.widgets

// Material's plates: what each global style stands a desktop widget on.
WidgetPlate {
    id: plate

    readonly property string dialect: (Config.options?.background?.widgets?.style ?? "panel") === "island"
        ? "island" : Appearance.globalStyle
    readonly property bool angel: plate.dialect === "angel"
    readonly property bool aurora: plate.dialect === "aurora" || plate.angel
    readonly property bool inir: plate.dialect === "inir"
    readonly property bool zzz: plate.dialect === "zzz"
    readonly property bool cookie: plate.dialect === "cookie"
    readonly property bool regalia: plate.dialect === "regalia"
    readonly property bool editorial: plate.dialect === "editorial"
    readonly property bool island: plate.dialect === "island"
    readonly property bool editorialStack: plate.editorial && plate.backed && Appearance.editorial.paperStack
    readonly property bool edged: plate.surface.surfaceBorderWidth > 0 && plate.surface.surfaceBorderOpacity > 0

    glass: !plate.island && plate.backed && plate.surface.surfaceUseBlur
        && Appearance.blurBackendFor("widgets", Appearance.blurTopology.unsupported) === "wallpaper"
        && (!plate.editorial || Appearance.editorial.glassActive)
    // The tint over the frosted wallpaper: the style's own at the usual 16 %, lighter below it and nearly solid at 100 %.
    readonly property real styleTint: 1 - Math.min(1, plate.angel ? Appearance.angel.overlayOpacity : Appearance.aurora.popupTransparentize * 1.2)
    readonly property real glassTint: plate.strength <= 0.16 ? plate.styleTint * (0.6 + plate.strength / 0.16 * 0.4)
        : plate.styleTint + (0.92 - plate.styleTint) * Math.max(0, (plate.strength - 0.16) / 0.84)
    glassSaturation: plate.angel ? Appearance.angel.blurSaturation * Appearance.angel.colorStrength : 0.15
    glassBlur: plate.editorial ? Appearance.editorial.glassBlur : plate.angel ? Appearance.angel.blurIntensity : 0.8

    moveDuration: Appearance.animation.elementMoveFast.duration
    moveType: Appearance.animation.elementMoveFast.type
    moveCurve: Appearance.animation.elementMoveFast.bezierCurve

    // An Island owns its material opacity: the widget's own would multiply it down to nothing.
    plateAlpha: !plate.backed ? 0 : plate.island ? 1
        : plate.editorial ? (plate.glass ? Appearance.editorial.glassOpacity : Math.min(1, 0.86 + plate.strength * 0.14))
        : plate.strength <= 0.16 ? 0.86 + plate.strength * 0.6 : 0.956 + (plate.strength - 0.16) / 0.84 * 0.044
    color: plate.editorialStack || plate.island || plate.glass || plate.zzz || plate.cookie || plate.regalia || plate.inir
        ? "transparent" : plate.backed ? plate.flatFill : "transparent"

    rimShown: !plate.editorialStack && !plate.zzz && !plate.cookie && !plate.regalia && !plate.island && !plate.angel
    rimColor: plate.inir ? ColorUtils.applyAlpha(Appearance.inir.colBorder, plate.surface.surfaceBorderOpacity * 3)
        : plate.aurora ? ColorUtils.applyAlpha(Appearance.aurora.colTooltipBorder, plate.surface.surfaceBorderOpacity)
        : plate.editorial ? ColorUtils.applyAlpha(Appearance.editorial.edge, Math.min(1, plate.surface.surfaceBorderOpacity * 2))
        : ColorUtils.applyAlpha(ColorUtils.ensureReadable(plate.surface.surfaceAccent, plate.flatFill, 3),
            Math.min(1, plate.surface.surfaceBorderOpacity * 2))

    Loader {
        anchors.fill: parent
        active: plate.zzz && plate.visible
        sourceComponent: ZzzPlate {
            // Plates here separate by fill, so the hairline stays subtle whatever the strength slider says.
            fillColor: plate.backed
                ? ColorUtils.applyAlpha(plate.surface.colorMode === "auto" ? Appearance.zzz.paper : plate.polarPlate, plate.plateAlpha)
                : "transparent"
            strokeColor: ColorUtils.applyAlpha(Appearance.zzz.onColor, Math.min(0.5, plate.surface.surfaceBorderOpacity * 1.4))
            strokeWidth: plate.surface.surfaceBorderWidth > 0 ? Appearance.zzz.hairlineThick : 0
            chamfer: Appearance.zzz.cutCorner
            radius: Appearance.zzz.round ? plate.radius : 0
        }
    }

    Loader {
        anchors.fill: parent
        active: plate.cookie && plate.visible && (plate.surface.surfaceOpacity > 0 || plate.edged)
        sourceComponent: CookieFace {
            role: "card"
            radius: plate.radius
            color: plate.backed ? ColorUtils.applyAlpha(plate.baseFill, plate.plateAlpha) : "transparent"
            strokeWidth: plate.surface.surfaceBorderWidth
            strokeColor: ColorUtils.applyAlpha(plate.surface.colorMode === "auto" ? Appearance.cookie.onColor
                : ColorUtils.contrastColor(plate.polarPlate), plate.surface.surfaceBorderOpacity)
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: plate.regalia && plate.edged
        radius: plate.radius
        color: "transparent"
        border.width: plate.surface.surfaceBorderWidth
        border.color: ColorUtils.applyAlpha(plate.surface.surfaceColor, Math.min(0.45, plate.surface.surfaceBorderOpacity * 0.6))
    }

    Rectangle {
        anchors.fill: parent
        visible: plate.glass && !plate.island && !plate.editorialStack
        color: plate.editorial ? plate.flatFill
            : ColorUtils.applyAlpha(Appearance.colors.colLayer0Base, plate.glassTint)
    }

    Loader {
        anchors.fill: parent
        active: plate.editorialStack && plate.visible
        sourceComponent: EditorialPaperStack {
            radius: plate.radius
            faceColor: plate.baseFill
            materialOpacity: plate.plateAlpha
            backingOpacity: plate.glass ? Appearance.editorial.glassBackingOpacity : plate.plateAlpha
            edgeWidth: plate.surface.surfaceBorderWidth
            edgeColor: ColorUtils.applyAlpha(Appearance.editorial.edge, plate.surface.surfaceBorderOpacity)
            backingEdgeColor: ColorUtils.applyAlpha(Appearance.editorial.accent, plate.surface.surfaceBorderOpacity)
        }
    }

    Loader {
        anchors.fill: parent
        active: plate.island && plate.backed && plate.visible
        sourceComponent: RicelinSurface {
            radius: plate.radius
            glassEnabled: plate.surface.powerActive
            screen: plate.QsWindow?.window?.screen ?? null
            glassScreenX: plate.surface.screenX
            glassScreenY: plate.surface.screenY
            glassScreenWidth: plate.surface.screenWidth
            glassScreenHeight: plate.surface.screenHeight
            shadow: false
        }
    }

    // Angel's stepped platform. Beside the plate, under it: inside, the clip and the glass mask would cut it away.
    StyledRectangularShadow {
        parent: plate.surface.parent
        z: plate.surface.z - 1
        target: plate.surface
        radius: plate.radius
        visible: plate.angel && plate.backed && plate.visible && !Appearance.gameModeMinimal
    }

    Rectangle {
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Appearance.angel.insetGlowHeight
        visible: plate.angel && plate.backed
        color: Appearance.angel.colInsetGlow
    }

    Loader {
        anchors.fill: parent
        active: plate.angel && plate.edged && plate.visible
        sourceComponent: AngelPartialBorder {
            targetRadius: plate.radius
            borderWidth: Math.max(1, plate.surface.surfaceBorderWidth)
            borderColor: ColorUtils.applyAlpha(Appearance.angel.colBorder, plate.surface.surfaceBorderOpacity)
        }
    }

    // The chassis shell panels stand on, so a widget stops reading as a generic card in another fill.
    Loader {
        anchors.fill: parent
        active: plate.regalia && plate.backed && plate.visible
        sourceComponent: RegaliaPlate {
            radius: plate.radius
            fillColor: ColorUtils.applyAlpha(plate.baseFill, plate.plateAlpha)
            inset: Appearance.regalia.surfaceInset
            elevated: true
        }
    }

    Rectangle {
        anchors.fill: parent
        visible: plate.inir && plate.backed
        radius: plate.radius
        color: ColorUtils.applyAlpha(plate.polarPlate, plate.plateAlpha)
    }
}
