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
    readonly property color fill: plate.clear || plate.glass
        ? ColorUtils.applyAlpha(IrisStyle.surface, plate.clear ? 0
            : IrisStyle.legibleVeil(plate.material, plate.surface.regionBrightness, 0, 1) * (plate.look.legibleAlways ? 1 : plate.share))
        : ColorUtils.applyAlpha(plate.surface.colorMode === "dark" ? ColorUtils.mix(IrisStyle.text, IrisStyle.accent, 0.98)
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
