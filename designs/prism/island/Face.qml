pragma ComponentBehavior: Bound
import QtQuick
import qs.modules.iris.style
import qs.modules.iris.components

// Prism's Island face: the hour over a short line of the spectrum (IrisStyle.prismStops, the shell's one), the light
// the hour splits into. No beam or fan beside it (his 11-21: they read as a scribble): the line sits centred under the
// figures and opens to their full width under the pointer. Only the rest belongs to it: a song rides as the engine's
// wings, the rest of the Island's moments are the engine's.
Item {
    id: root
    property var island: null
    readonly property var modes: ["idle", "clock"]
    readonly property real d: IrisStyle.density
    readonly property real h: root.island?.compactHeight ?? 42
    readonly property real pad: Math.round(Math.max(14 * root.d, root.h * 0.36))
    readonly property real contentWidth: clock.implicitWidth + 2 * root.pad
    readonly property real line: Math.max(2, Math.round(2 * root.d))
    readonly property real gap: Math.max(2, Math.round(3 * root.d))
    readonly property var stops: IrisStyle.prismStops

    HoverHandler { id: hover }

    IrisClock {
        id: clock
        anchors.horizontalCenter: parent.horizontalCenter
        // The hour and its line stand as one block in the strip's middle.
        y: Math.round((root.height - clock.height - root.gap - root.line) / 2)
        family: IrisStyle.figureFace(pixelSize)
        minorFamily: family
        pixelSize: root.island?.figureSize ?? IrisStyle.typeHeadline
        separatorColor: IrisStyle.textSecondary
    }

    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: clock.y + clock.height + root.gap
        height: root.line
        radius: IrisStyle.capsule(height)
        width: Math.round(clock.width * (hover.hovered ? 1 : 0.42))
        Behavior on width { NumberAnimation { duration: IrisStyle.duration(260); easing.type: Easing.OutCubic } }
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: root.stops[0] }
            GradientStop { position: 1 / 6; color: root.stops[1] }
            GradientStop { position: 2 / 6; color: root.stops[2] }
            GradientStop { position: 3 / 6; color: root.stops[3] }
            GradientStop { position: 4 / 6; color: root.stops[4] }
            GradientStop { position: 5 / 6; color: root.stops[5] }
            GradientStop { position: 1; color: root.stops[6] }
        }
    }
}
