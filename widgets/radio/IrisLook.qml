pragma ComponentBehavior: Bound

// The tuner in iRiS, from the Island's face or the desktop card while iRiS is worn.
import QtQuick
import qs.modules.common.functions
import qs.modules.common.widgets
import qs.modules.iris.style
import qs.modules.iris.components

Item {
    id: root

    // The tuner in Prism's grammar, the look of iRiS Settings: its own neutrals (canvas, a lighter rail, raised
    // fields), white solids with black ink, the accent as a plate and ink only where you are, and the haze.
    readonly property color prismRail: IrisStyle.light ? "#ebebee" : "#161618" // iris-literal: Prism's side column
    readonly property color prismInk: IrisStyle.light ? "#1d1d1f" : "#ffffff" // iris-literal: Prism's text
    readonly property color prismAccentInk: {
        const hue = Qt.color(IrisStyle.accent)
        for (let step = 0; step <= 10; step++) {
            const ink = ColorUtils.mix(root.prismInk, hue, step / 10)
            if (ColorUtils.contrastRatio(ink, root.prismRail) >= 4.5) return ink
        }
        return root.prismInk
    }
    readonly property var look: ({
        grammar: "prism",
        d: IrisStyle.density,
        font: IrisStyle.fontMain,
        caption: IrisStyle.typeFootnote,
        small: IrisStyle.typeMeta,
        meta: IrisStyle.typeMeta,
        body: IrisStyle.typeBody,
        title: IrisStyle.typeTitle,
        display: Math.round(28 * IrisStyle.typeScale), // iris-literal: Prism's page title
        bg: IrisStyle.light ? "#f5f5f7" : "#0f0f11", // iris-literal: Prism's middle column
        rail: root.prismRail,
        raised: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.045) : Qt.rgba(1, 1, 1, 0.055), // iris-literal: Prism's fill
        track: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09), // iris-literal: Prism's hover fill
        hover: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09), // iris-literal: Prism's hover fill
        press: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.11) : Qt.rgba(1, 1, 1, 0.13), // iris-literal: Prism's press fill
        selected: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09), // iris-literal: Prism's hover fill
        ink: root.prismInk,
        inkNav: IrisStyle.light ? "#3a3a3c" : "#d6d6db", // iris-literal: a place's name in Prism's sidebar
        muted: IrisStyle.light ? "#6e6e73" : "#a6a6ad", // iris-literal: Prism's secondary label
        faint: IrisStyle.light ? "#8e8e93" : "#6e6e75", // iris-literal: Prism's numbers and captions
        line: IrisStyle.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.065), // iris-literal: Prism's hairline
        accent: IrisStyle.accent,
        onAccent: IrisStyle.inkOnAccent,
        accentInk: root.prismAccentInk,
        accentPlate: ColorUtils.applyAlpha(IrisStyle.accent, IrisStyle.light ? 0.13 : 0.16), // iris-literal: Prism's open-place plate
        solid: root.prismInk,
        onSolid: IrisStyle.light ? "#ffffff" : "#000000", // iris-literal: ink on Prism's solid
        spectrum: IrisStyle.prismStops,
        danger: IrisStyle.danger,
        scrim: ColorUtils.applyAlpha(IrisStyle.scrim, 0.32),
        radius: IrisStyle.radiusPanel,
        radiusSmall: Math.round(9 * IrisStyle.density), // iris-literal: Prism's small plates
        glyph: irisGlyph,
        backdrop: irisHaze
    })
    Component {
        id: irisHaze
        IrisPrismHaze {
            radius: IrisStyle.radiusPanel
            from: "bottomRight"
            strength: 0.55
        }
    }
    Component {
        id: irisGlyph
        MaterialSymbol {
            property string name: ""
            property real size: 20
            property bool filled: false
            text: name
            iconSize: size
            fill: filled ? 1 : 0
        }
    }
}
