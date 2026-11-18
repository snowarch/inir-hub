pragma ComponentBehavior: Bound

import QtQuick
import qs.services
import qs.modules.common
import qs.modules.nihil.style

// The signal: the one colour NiHiL lights what is on with. A hue of the person's own opens a line of dots to pick it.
Column {
    id: root

    readonly property string mode: String(Config.getNestedValue("nihil.theme.accent", "signal"))
    readonly property var modes: [
        { value: "signal", label: Translation.tr("Signal"), swatch: () => NihilStyle.signalColor },
        { value: "dynamic", label: Translation.tr("Wallpaper"), swatch: () => NihilStyle.wallpaperColor },
        { value: "tertiary", label: Translation.tr("Second"), swatch: () => NihilStyle.secondColor },
        { value: "ink", label: Translation.tr("Ink"), swatch: () => NihilStyle.ink },
        { value: "custom", label: Translation.tr("Yours"), swatch: () => NihilStyle.hueColor(NihilStyle.hue) }
    ]

    spacing: NihilStyle.s(14)

    Flow {
        width: root.width
        spacing: NihilStyle.s(4)
        Repeater {
            model: root.modes
            NSwatch {
                required property var modelData
                swatch: modelData.swatch()
                label: modelData.label
                chosen: root.mode === modelData.value
                onPicked: Config.setNestedValue("nihil.theme.accent", modelData.value)
            }
        }
    }
    NHueDots {
        visible: root.mode === "custom"
        width: root.width
        height: implicitHeight
        name: Translation.tr("Hue")
        hue: NihilStyle.hue
        onMoved: degrees => Config.previewNestedValue("nihil.theme.hue", degrees)
        onReleased: degrees => Config.setNestedValue("nihil.theme.hue", degrees)
    }
}
