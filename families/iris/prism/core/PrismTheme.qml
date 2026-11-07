pragma Singleton
import QtQuick
import Quickshell
import qs.modules.common.functions
import qs.modules.iris.style

// Prism's own tokens: the dark music app of his 11-06 reference (near-black columns, grey captions, hairlines, white
// controls) and its light counterpart. Fonts, density and the person's accent come from IrisStyle; nothing here is read
// by any other surface.
Singleton {
    id: root

    readonly property bool light: IrisStyle.light
    readonly property real density: IrisStyle.settingsDensity
    function dp(value: real): real { return Math.round(value * root.density) }

    // The three columns, each a step apart as in the reference: the side rails a touch lighter than the middle.
    readonly property color canvas: root.light ? "#f5f5f7" : "#0f0f11" // iris-literal: Prism's middle column, its own neutral
    readonly property color rail: root.light ? "#ebebee" : "#161618" // iris-literal: Prism's side columns
    readonly property color raised: root.light ? "#ffffff" : "#1e1e21" // iris-literal: circles and fields standing on a rail
    readonly property color sunk: root.light ? "#e2e2e6" : "#050506" // iris-literal: a switch's track, darker than the page
    readonly property color line: root.light ? Qt.rgba(0, 0, 0, 0.08) : Qt.rgba(1, 1, 1, 0.065) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fill: root.light ? Qt.rgba(0, 0, 0, 0.045) : Qt.rgba(1, 1, 1, 0.055) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillHover: root.light ? Qt.rgba(0, 0, 0, 0.075) : Qt.rgba(1, 1, 1, 0.09) // iris-literal: Prism's own fills and scrims, scheme-aware above
    readonly property color fillPress: root.light ? Qt.rgba(0, 0, 0, 0.11) : Qt.rgba(1, 1, 1, 0.13) // iris-literal: Prism's own fills and scrims, scheme-aware above

    readonly property color ink: root.light ? "#1d1d1f" : "#ffffff" // iris-literal: Prism's text, Apple's label colours
    readonly property color ink2: root.light ? "#6e6e73" : "#8e8e93" // iris-literal: secondary label
    readonly property color ink3: root.light ? "#a1a1a6" : "#56565b" // iris-literal: tertiary label, numbers, headers

    // The reference's white controls: a white pill on dark, its ink black; in light the same idea inverted.
    readonly property color solid: root.light ? "#1d1d1f" : "#ffffff" // iris-literal: the primary pill and chosen segment
    readonly property color inkSolid: root.light ? "#ffffff" : "#000000" // iris-literal: ink on that pill

    readonly property color accent: IrisStyle.accent
    readonly property color inkAccent: IrisStyle.inkOnAccent

    // Art stays dark in every scheme, like a record sleeve: the hero, the player, the glass card.
    readonly property color night: "#08080a" // iris-literal: the refraction's black, the same in every scheme
    readonly property color paper: "#ffffff" // iris-literal: light on the art, the same in every scheme

    // Tints for the row marks: one per page, so a row found by search still says where it lives.
    readonly property var tints: ({
        blue: "#4289fd", violet: "#a259ff", pink: "#ff3d8b", green: "#26c25a", amber: "#ffaa1d", // iris-literal: the refraction's spectrum, reused as page tints
        red: "#ff453a", teal: "#30c6c8", indigo: "#6e6bff", orange: "#ff8a1f", grey: "#8e8e93" // iris-literal: the refraction's spectrum, reused as page tints
    })
    function tint(name: string): color { return root.tints[name] ?? root.tints.grey }

    readonly property string fontMain: IrisStyle.fontMain
    readonly property string fontMono: IrisStyle.fontMono
    readonly property string fontNumbers: IrisStyle.fontNumbers.length > 0 ? IrisStyle.fontNumbers : IrisStyle.fontMain

    // The type ladder, in px at density 1: caption, small, body, row, head, title, display.
    readonly property real caption: 11 * IrisStyle.typeScale
    readonly property real small: 12 * IrisStyle.typeScale
    readonly property real body: 13 * IrisStyle.typeScale
    readonly property real row: 14 * IrisStyle.typeScale
    readonly property real head: 18 * IrisStyle.typeScale
    readonly property real title: 28 * IrisStyle.typeScale
    readonly property real display: 30 * IrisStyle.typeScale

    readonly property bool motion: IrisStyle.motionEnabled
    function ms(value: int): int { return root.motion ? value : 0 }
}
