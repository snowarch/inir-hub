import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions
import qs.modules.iris.style

// Prism's picture in Settings › Design, in its own colours whatever Design is on (a Design shows what it is): over
// Prism's black, a white beam from the lower left breaks on a glass prism and leaves as the spectrum toward the upper
// right, as on the N7 specimen card of Prism's references; the wordmark and its captions printed in mono beside it.
Rectangle {
    id: root
    readonly property real u: height / 100
    color: "#08080a" // iris-literal: Prism's night, its own black in its picture
    clip: true
    // The spectrum, red to violet: the refraction recipe's stops (Prism Settings' hero).
    readonly property var bands: ["#fd1443", "#fd9017", "#fef23d", "#26e033", "#4289fd", "#7a9afd", "#d518fd"] // iris-literal: the recipe's spectrum
    readonly property point prism: Qt.point(root.width * 0.42, 56 * root.u)

    component Band: ShapePath {
        id: band
        required property int index
        readonly property real share: 64 * root.u / root.bands.length
        strokeWidth: -1
        strokeColor: "transparent"
        fillGradient: LinearGradient {
            x1: root.prism.x; y1: 0
            x2: root.width; y2: 0
            GradientStop { position: 0; color: "#ffffff" } // iris-literal: the white core where the bands meet
            GradientStop { position: 0.18; color: root.bands[band.index] }
            GradientStop { position: 1; color: ColorUtils.applyAlpha(root.bands[band.index], 0.05) }
        }
        startX: root.prism.x + 6 * root.u; startY: root.prism.y - 4 * root.u
        PathLine { x: root.width; y: -14 * root.u + band.index * band.share }
        PathLine { x: root.width; y: -14 * root.u + (band.index + 1) * band.share }
        PathLine { x: root.prism.x + 6 * root.u; y: root.prism.y - 4 * root.u }
    }

    Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // The beam.
        ShapePath {
            strokeWidth: -1
            strokeColor: "transparent"
            fillGradient: LinearGradient {
                x1: 0; y1: 0
                x2: root.prism.x; y2: 0
                GradientStop { position: 0; color: ColorUtils.applyAlpha("#ffffff", 0.1) } // iris-literal: white light
                GradientStop { position: 1; color: "#ffffff" } // iris-literal: white light
            }
            startX: 0; startY: 92 * root.u
            PathLine { x: root.prism.x - 4 * root.u; y: root.prism.y + 1 * root.u }
            PathLine { x: root.prism.x - 4 * root.u; y: root.prism.y + 2.4 * root.u }
            PathLine { x: 0; y: 95 * root.u }
        }
        Band { index: 0 }
        Band { index: 1 }
        Band { index: 2 }
        Band { index: 3 }
        Band { index: 4 }
        Band { index: 5 }
        Band { index: 6 }
        // The prism: clear glass with bright edges.
        ShapePath {
            strokeWidth: Math.max(1, 0.8 * root.u)
            strokeColor: ColorUtils.applyAlpha("#ffffff", 0.85) // iris-literal: the glass's lit edge
            joinStyle: ShapePath.RoundJoin
            fillColor: ColorUtils.applyAlpha("#ffffff", 0.1) // iris-literal: the glass
            startX: root.prism.x; startY: root.prism.y - 20 * root.u
            PathLine { x: root.prism.x + 17 * root.u; y: root.prism.y + 10 * root.u }
            PathLine { x: root.prism.x - 17 * root.u; y: root.prism.y + 10 * root.u }
            PathLine { x: root.prism.x; y: root.prism.y - 20 * root.u }
        }
    }

    // The captions, printed in mono on the art.
    Text {
        x: 6 * root.u; y: 6 * root.u
        text: "IRIS DESIGN  /  01"
        color: "#8e8e93" // iris-literal: Prism's secondary label
        font.family: IrisStyle.fontMono; font.pixelSize: 4.2 * root.u; font.letterSpacing: 0.8 * root.u
    }
    Row {
        x: 6 * root.u; y: 13 * root.u
        spacing: 1.6 * root.u
        Repeater {
            model: 12
            Rectangle {
                required property int index
                width: Math.max(1, 0.4 * root.u); height: (index % 4 === 0 ? 3 : 1.6) * root.u
                color: "#56565b" // iris-literal: Prism's tertiary label, the tick ruler
            }
        }
    }
    Column {
        x: 6 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 6 * root.u
        spacing: 0.6 * root.u
        Text {
            text: "WHITE LIGHT  →  SPECTRUM"
            color: "#8e8e93" // iris-literal: Prism's secondary label
            font.family: IrisStyle.fontMono; font.pixelSize: 3.6 * root.u; font.letterSpacing: 0.6 * root.u
        }
        Text {
            text: "prism"
            color: "#ffffff" // iris-literal: Prism's ink
            font.family: IrisStyle.fontRead; font.weight: Font.DemiBold; font.pixelSize: 17 * root.u
            font.letterSpacing: -0.7 * root.u
        }
    }
    Insignia {
        anchors.right: parent.right; anchors.rightMargin: 6 * root.u
        anchors.bottom: parent.bottom; anchors.bottomMargin: 7 * root.u
        width: 11 * root.u; height: width
        ink: "#ffffff" // iris-literal: Prism's ink
    }
}
