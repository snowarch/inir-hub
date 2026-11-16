pragma ComponentBehavior: Bound

// The minute's horizon in an iRiS face, drawn with the family's FaceArea (the Day's line): what came in rises above
// the line, what went out hangs under it, on one scale (traffic.js `levels`), the newest second at the right. Until a
// minute is kept it grows in from the right. Prism lays its spectrum over what came in (`inEffect`).
import QtQuick
import qs.modules.iris.widgets

Item {
    id: root

    required property var face
    property var downs: []
    property var ups: []
    property real filled: 1
    property color inTint: root.face.accent
    property color outTint: root.face.accent2
    // What came in takes the room above the line.
    property real split: 0.56
    property Component inEffect: null
    // The line both halves stand on, across the whole minute even while it fills.
    property color axis: root.face.fillActive

    readonly property real from: 1 - Math.max(0, Math.min(1, root.filled))
    function at(values: var, t: real): real {
        return IrisFaceData.smooth(values, (t - root.from) / Math.max(0.001, 1 - root.from))
    }

    FaceArea {
        id: incoming
        face: root.face
        width: root.width
        height: Math.round(root.height * root.split)
        from: root.from
        curve: t => root.at(root.downs, t)
        tint: root.inTint
        guide: false
        layer.enabled: root.inEffect !== null
        layer.smooth: true
        layer.effect: root.inEffect
    }
    Rectangle {
        width: root.width
        height: Math.max(1, root.face.dp(1))
        y: incoming.height - height
        color: root.axis
    }
    FaceArea {
        id: outgoing
        face: root.face
        y: incoming.height
        width: root.width
        height: root.height - incoming.height
        from: root.from
        curve: t => root.at(root.ups, t)
        tint: root.outTint
        guide: false
        transform: Scale { origin.y: outgoing.height / 2; yScale: -1 }
    }
}
