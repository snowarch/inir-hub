import QtQuick
import qs.modules.common.functions
import qs.modules.iris.style
import qs.modules.shared.background.widgets

// A widget with no iRiS face of its own still stands on the Island's material, and its own Look wins over the shared row.
WidgetPlate {
    id: plate

    readonly property var look: DesktopWidgetLook.look
    readonly property var widget: plate.surface.widget
    readonly property string material: plate.look.material(plate.widget)
    readonly property bool clear: plate.material === "clear"
    readonly property string outline: plate.look.outline(plate.widget)
    readonly property real share: plate.look.surfaceOpacity(plate.widget)
    readonly property bool lightBackdrop: plate.surface.colorMode === "dark" ? true
        : plate.surface.colorMode === "light" ? false
        : IrisStyle.light && !plate.clear ? true
        : plate.glass ? Boolean(plate.widget?.glassInkOnLight) : false
    readonly property bool paper: IrisStyle.light && !plate.clear
    readonly property real readLevel: plate.look.legibleAlways ? Math.max(0.72, plate.surface.regionBrightness) : plate.surface.regionBrightness
    readonly property real frostLevel: plate.look.legibleAlways ? Math.min(0.5, plate.surface.regionBrightness) : plate.surface.regionBrightness
    readonly property real readSpread: plate.look.legibleAlways ? Math.max(0.24, Number(plate.widget?.regionBrightnessSpread ?? 0)) : Number(plate.widget?.regionBrightnessSpread ?? 0)
    readonly property string readMaterial: plate.look.legibleAlways ? "panel" : plate.material
    readonly property bool rinLiquid: plate.compositorGlass && IrisCompositorBlur.background === "liquid"
    readonly property real glassAlpha: plate.clear ? 0
        : plate.rinLiquid ? IrisStyle.liquidVeil(plate.share)
        : plate.compositorGlass ? Math.max(0.14, Math.min(0.46, plate.share * 0.44))
        : (plate.paper ? IrisStyle.legibleVeil(plate.readMaterial, plate.frostLevel, plate.readSpread, 1)
            : plate.lightBackdrop ? IrisStyle.legibleFrost(plate.readMaterial, plate.frostLevel, plate.readSpread, 1)
            : IrisStyle.legibleVeil(plate.readMaterial, plate.readLevel, plate.readSpread, 1))
            * (plate.look.legibleAlways ? 1 : plate.paper ? 0.52 + 0.48 * plate.share : plate.share)
    readonly property color glassSurface: plate.lightBackdrop && !plate.paper ? IrisStyle.frost : IrisStyle.surface
    readonly property color fill: plate.clear || plate.glass
        ? ColorUtils.applyAlpha(plate.glassSurface, plate.glassAlpha)
        : ColorUtils.applyAlpha(plate.surface.colorMode === "dark" ? IrisStyle.frost
            : plate.surface.colorMode === "light" ? IrisStyle.darkSurfaceOpaque
            : plate.look.plate(plate.widget),
            plate.backed ? Math.min(1, 0.72 + plate.strength * 0.28) * plate.share : 0)

    glass: plate.backed && plate.material === "glass"
    color: plate.glass ? "transparent" : plate.fill
    rimShown: plate.outline === "always" || plate.outline !== "none" && (!plate.clear || plate.look.rim)
    rimColor: ColorUtils.applyAlpha(plate.surface.surfaceColor, plate.surface.surfaceBorderOpacity)

    Rectangle {
        anchors.fill: parent
        visible: plate.glass
        color: plate.fill
    }
}
