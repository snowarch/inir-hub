import QtQuick
import QtQuick.Shapes
import qs.modules.common.functions
import qs.modules.iris.style

// The Prism insignia: a glass triangle in the ink, a thread of light entering its left face and the spectrum leaving
// its right one. Drawn on a 100-unit grid and scaled to the host's size; small, the fan keeps three bands. A host that
// asks for a colour other than the accent (a lit tile's ink) gets the whole mark in that colour.
Item {
    id: root
    property Item host: null
    property color ink: !root.host || Qt.colorEqual(root.host.color, IrisStyle.accent) ? IrisStyle.text : root.host.color
    readonly property bool mono: !!root.host && !Qt.colorEqual(root.host.color, IrisStyle.accent)
    readonly property real size: Math.min(width, height)
    readonly property real unit: root.size / 100
    readonly property bool small: root.size < 40
    // Red to violet, top to bottom (IrisStyle.prismStops runs violet to red).
    readonly property var bands: {
        const all = Array.from(IrisStyle.prismStops).reverse()
        return root.small ? [all[0], all[3], all[6]] : all
    }

    component Band: ShapePath {
        id: band
        required property int index
        readonly property real share: 30 / root.bands.length
        strokeWidth: -1
        strokeColor: "transparent"
        fillColor: root.mono ? ColorUtils.applyAlpha(root.ink, 0.35 + 0.6 * (1 - band.index / root.bands.length)) : (root.bands[band.index] ?? root.ink)
        startX: 66; startY: 50
        PathLine { x: 98; y: 38 + band.index * band.share }
        PathLine { x: 98; y: 38 + (band.index + 1) * band.share }
        PathLine { x: 66; y: 50 }
    }

    Shape {
        width: 100
        height: 100
        anchors.centerIn: parent
        scale: root.unit
        preferredRendererType: Shape.CurveRenderer
        // The beam, from the lower left into the left face.
        ShapePath {
            strokeWidth: root.small ? 7 : 4
            strokeColor: root.ink
            capStyle: ShapePath.RoundCap
            fillColor: "transparent"
            startX: 2; startY: 64
            PathLine { x: 33; y: 50 }
        }
        Band { index: 0 }
        Band { index: 1 }
        Band { index: 2 }
        Band { index: 3 }
        Band { index: 4 }
        Band { index: 5 }
        Band { index: 6 }
        // The glass: drawn last so the light meets its faces.
        ShapePath {
            strokeWidth: root.small ? 9 : 6
            strokeColor: root.ink
            joinStyle: ShapePath.RoundJoin
            fillColor: ColorUtils.applyAlpha(root.ink, 0.12)
            startX: 50; startY: 14
            PathLine { x: 84; y: 80 }
            PathLine { x: 16; y: 80 }
            PathLine { x: 50; y: 14 }
        }
    }
}
